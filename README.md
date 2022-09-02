# Borg Backup 
This is a set of useful scripts for setting up a borg backup to a (remote) repository. 
Features:
* Defining variables, exclude and include patterns via config / env files
* Backup script for creating / updating backups as well as pruning
* Automated mounting of repository to a local folder for easy browsing and restoring from the archive

## Test environment 
* Ubuntu 18.04 / 20.04
* BorgBackup 1.2 
* Remote repository: Hetzner Storage Box (ssh / rsync)

## Setup 
* clone this repo
* copy `.env.example` to `.env` and set your vars 
* make all scripts executable with `chmod +x *.sh`

### Initialize
* run `borg-init.sh` to intialize remote repo 
* the repo will be setup with the passphrase configured in `.env`
* the encryption key will be copied to the current directory - please store it in secure location and remove it
* copy `patterns.example.lst` to `patterns.lst` to define your included and excluded patterns, the script is using the `patterns-from` feature - see here for details https://manpages.debian.org/testing/borgbackup/borg-patterns.1.en.html 


### Running Backups
* run `borg-backup.sh` to create initial backup
* add entry to crontab for daily backups: 
```
0 3 * * * /MY_PATH_TO/borg-backup/borg-backup.sh > /dev/null 2>&1
```
* check logfile (see .env) for results or errors

### Restoring Backups
* configure restore folder in `.env`, e.g. `/mnt/borg`
* run `borg-mount.sh` - this will mount the repository to the defined location 
* now you can browse all archives and restore files via bash
* be sure to unmount the restore folder with `borg umount MY_RESTORE_FOLDER`

For questions please contact ep@studiomitte.com
