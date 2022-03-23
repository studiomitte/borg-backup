#!/usr/bin/env bash

###############################
# script mounts borg repo from .env
# to defined mount directory
# DO NOT FORGET TO UNMOUNT!!
# borg unmount MOUNT_DIR
##############################


# load values from .env
set -o allexport
eval $(cat '.env' | sed -e '/^#/d;/^\s*$/d' -e 's/\(\w*\)[ \t]*=[ \t]*\(.*\)/\1=\2/' -e "s/=['\"]\(.*\)['\"]/=\1/g" -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +o allexport

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO=${ENV_BORG_REPO}
export BORG_PASSPHRASE=${ENV_BORG_PASSPHRASE}
export BORG_RESTORE_MOUNT=${ENV_BORG_RESTORE_MOUNT}

echo 
echo
echo "----------------------------------------"
echo "--- MOUNTING BACKUP REPO FOR RESTORE ---"
echo "----------------------------------------"
echo

# first try to unmount if existting
if borg umount ${BORG_RESTORE_MOUNT}; then
    echo "Restore folder unmounted"
else
    echo "No restore folder mounted!"
fi


##
## mount repo restore to defined directory
##

mkdir -p ${BORG_RESTORE_MOUNT}
chmod a-w ${BORG_RESTORE_MOUNT}

echo "Mounting Repository to ${BORG_RESTORE_MOUNT}"

borg mount ${BORG_REPO} ${BORG_RESTORE_MOUNT}

echo "Switch to ${BORG_RESTORE_MOUNT} to browse backup archives!"
echo 
echo "--- Showing list of available backups ---"
echo 
ls -al ${BORG_RESTORE_MOUNT}
echo 
echo 
echo "-------------------------------------------"
echo "MAKE SURE TO UNMOUNT REPO WHEN FINISHED WHITH"
echo "$ borg umount ${BORG_RESTORE_MOUNT}"
echo "-------------------------------------------"
