#!/usr/bin/env bash

# get current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# load values from .env
set -o allexport
eval $(cat ${DIR}'/.env' | sed -e '/^#/d;/^\s*$/d' -e 's/\(\w*\)[ \t]*=[ \t]*\(.*\)/\1=\2/' -e "s/=['\"]\(.*\)['\"]/=\1/g" -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +o allexport

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO=${ENV_BORG_REPO}
# See the section "Passphrase notes" for more infos.
export BORG_PASSPHRASE=${ENV_BORG_PASSPHRASE}
export BORG_RESTORE_MOUNT=${ENV_BORG_RESTORE_MOUNT}
LOG=${ENV_BORG_LOG_DIRECTORY}${ENV_BORG_LOG_FILE}



##
## write output to log file
##

exec > >(tee -i ${LOG})
exec 2>&1

# first try to unmount repository if existting
if borg umount ${BORG_RESTORE_MOUNT}; then
    echo "Restore folder unmounted"
else
    echo "No restore folder mounted!"
fi


# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"

# Backup the most important directories into an archive named after
# the machine this script is currently running on:
# check the file patterns.lst for including and excluding stuff

borg create                         \
    --warning                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --show-rc                       \
    --compression lz4               \
    --exclude-caches                \
    --exclude '/home/*/.cache/*'    \
    --exclude '/var/tmp/*'          \
    ::'{hostname}-{now}'            \
    --patterns-from ${DIR}'/patterns.lst'

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

borg prune                          \
    --list                          \
    --prefix '{hostname}-'          \
    --show-rc                       \
    --keep-daily    14              \
    --keep-weekly   4               \
    --keep-monthly  6               \

prune_exit=$?


# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 0 ]; then
    info "Backup, Prune, and Compact finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    info "Backup, Prune, and/or Compact finished with warnings"
else
    info "Backup, Prune, and/or Compact finished with errors"
fi


################################################
# email result to configured email address (see .env)
# using "mail" command (postfix, sendmail..)
################################################

# date and time
ts_now="$(date +"%d.%m.%Y - %T")"

# 0: disable email 
# 1: enable email (default)
email_enabled=${ENV_BORG_EMAIL_ENABLED:-1}

# mail address to send backup report to
email_address=${ENV_BORG_EMAIL_ADDRESS}

#mail message, log file content will be appended
email_message="Borg Backup Report: $HOSTNAME / $ts_now"

# send level of information based on borg return code
# 0: info / verbose
# 1: warning (default)
# >1: error
email_level=${ENV_BORG_EMAIL_LEVEL:-1}

# send mail if global_exit equals to configured level or higher
if [[ ${email_enabled} -gt 0 && ${global_exit} -ge ${email_level} ]]; then
    # send logfile as attachement - parameter "-A" works on debian / ubuntu
    echo "${email_message}" | mail -s "${email_message}" -A ${LOG} ${email_address}
    info "Mail sent successfully to ${email_address}"
fi

