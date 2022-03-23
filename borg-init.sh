###############################
# script inits borg repo
# vars are set in .env
##############################


# load values from .env
set -o allexport
eval $(cat '.env' | sed -e '/^#/d;/^\s*$/d' -e 's/\(\w*\)[ \t]*=[ \t]*\(.*\)/\1=\2/' -e "s/=['\"]\(.*\)['\"]/=\1/g" -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
set +o allexport

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO=${ENV_BORG_REPO}
export BORG_PASSPHRASE=${ENV_BORG_PASSPHRASE}
LOG_DIRECTORY=${ENV_BORG_LOG_DIRECTORY}

echo
echo
echo "----------------------------------------"
echo "  INIT BORG REPO"
echo "----------------------------------------"
echo

# check for existing repo - if yes, abort script
if borg check ${BORG_REPO}; then
    echo "repo exists"
    exit 1
else
    # init REPO with passphrase from .env
    echo
    echo "Init Repostory:"
    borg init --encryption repokey ${BORG_REPO}
    echo
    echo "Exporting Key"
    borg key export ${BORG_REPO} ./key.txt
    echo "Create Log Directory"
    mkdir ${LOG_DIRECTORY}
fi
