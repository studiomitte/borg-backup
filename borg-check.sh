#!/usr/bin/env bash

###############################
# script checks borg repo from .env
# USING REPAIR CAN BE DANGEROUS!!
##############################

REPAIR=
PROGRESS="-p"
ARCHIVESONLY=
REPOSITORYONLY=

function usage {
    if [[ -n $1 ]]; then
        echo "$1"
    fi
    echo -e "usage $0 [--rep] []"
    echo "  -q      Quiet. Don't show progress."
    echo "  --rep   Will try to repair. This can damage your backup. "
}

while [[ $# -ne 0 ]]; do
    case $1 in       
        --rep) REPAIR="--repair";;
        -a) ARCHIVESONLY="--archives-only";;
        -r) REPOSITORYONLY="--repository-only";;
        -q) PROGRESS="";;
        -h) usage; exit 1;;
    esac    
    shift
done


# load values from .env
set -o allexport
eval $(cat '.env' | sed -e '/^#/d;/^\s*$/d' -e 's/\(\w*\)[ \t]*=[ \t]*\(.*\)/\1=\2/' -e "s/=['\"]\(.*\)['\"]/=\1/g" -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +o allexport

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO=${ENV_BORG_REPO}
export BORG_PASSPHRASE=${ENV_BORG_PASSPHRASE}

echo 
echo
echo "----------------------------"
echo "--- CHECKING BACKUP REPO ---"
echo "----------------------------"
echo

borg check    \
    $PROGRESS       \
    $ARCHIVESONLY   \
    $REPOSITORYONLY \
    $REPAIR
