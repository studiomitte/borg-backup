#!/usr/bin/env bash

# get current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# load values from .env
set -o allexport
eval $(cat ${DIR}'/.env' | sed -e '/^#/d;/^\s*$/d' -e 's/\(\w*\)[ \t]*=[ \t]*\(.*\)/\1=\2/' -e "s/=['\"]\(.*\)['\"]/=\1/g" -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +o allexport

set -e
set -o pipefail

if [[ ! "${ENV_SYNC_REPOSITORY_PATH:-}" =~ [^[:space:]] ]]; then
    echo "ENV_SYNC_REPOSITORY_PATH must be set to the local repository directory." >&2
    exit 2
fi

if [[ ! -d "${ENV_SYNC_REPOSITORY_PATH}" ]]; then
    echo "Source repository directory does not exist: ${ENV_SYNC_REPOSITORY_PATH}" >&2
    exit 2
fi

if [[ ! "${ENV_SYNC_TARGET_PATH:-}" =~ [^[:space:]] ]]; then
    echo "ENV_SYNC_TARGET_PATH must be set to the rclone destination." >&2
    exit 2
fi

exec 9>"${DIR}/.wasabisync.lock" || exit 2

if ! flock -n 9; then
    echo "Unable to acquire Wasabi sync lock; another run may be active." >&2
    exit 75
fi

#Lets see how much space is used by directory to back up

#if directory is gone, or has gotten small, we will exit
space=`du -Ls -- "${ENV_SYNC_REPOSITORY_PATH}"|awk '{print $1}'`

if (( $space < 400000 )); then
    echo "EXITING - not enough space used in ${ENV_SYNC_REPOSITORY_PATH}"
    exit 1
fi

/usr/bin/borg --lock-wait 600 with-lock "${ENV_SYNC_REPOSITORY_PATH}" \
    /usr/bin/rclone -v sync "${ENV_SYNC_REPOSITORY_PATH}" "${ENV_SYNC_TARGET_PATH}" \
    >> "${DIR}/wasabi-sync.log" 2>&1
mail -s "Wasabisync" ${ENV_BORG_EMAIL_ADDRESS}<"${DIR}/wasabi-sync.log"
