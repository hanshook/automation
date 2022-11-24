#! /bin/bash

cd $(dirname $0)
. log_utils

[[ $EUID -eq 0 ]] && log_fatal 88 "You are running as root - run as yourself..."

# Load and check configuration
# ============================

INSTALL_CONFIG=./automation.cfg

log_info "Reading configuration file ${INSTALL_CONFIG}"

[ ! -e ${INSTALL_CONFIG} ] && log_fatal 99 "Configuration file ${INSTALL_CONFIG} not found"

. ${INSTALL_CONFIG}

log_info "Checking configuration values and setting defaults"

#: ${CLI_VENV_DIR:=".adminclivenv"}
#: ${CLI_ENV_FILE_NAME:="admincli"}


[ -z "${CLI_VENV_DIR}" ]  && log_fatal 91 "CLI_VENV_DIR not defined in ${INSTALL_CONFIG}"
[ -z "${CLI_ENV_FILE_NAME}" ]  && log_fatal 91 "CLI_ENV_FILE_NAME not defined in ${INSTALL_CONFIG}"

    
log_info "Configuration seems valid - OK"

# Dependencies
# ============

log_info "Check that the user has an ssh public key"

if [ ! -e ${HOME}/.ssh/id_rsa.pub ]
then
    log_warn "Unable to find ${HOME}/.ssh/id_rsa.pub ... this setup assumes you have a private key"
else
    log_info "Found ${HOME}/.ssh/id_rsa.pub - ok"
fi

log_info "Install required ubuntu packages"

if sudo apt-get install -qq -y python3-dev python3-pip virtualenvwrapper build-essential wget snapd ca-certificates pass > /dev/null
then
    log_info "Required ubuntu packages installed - ok"
else
    log_fatal 92 "Unable to install required ubuntu packages"
fi


log_info "Create a CLI Python venv for automation"

if [ -e "${HOME}/${CLI_VENV_DIR}" ]
then
    log_info "Found a previous CLI Python venv at ${HOME}/${CLI_VENV_DIR} - removing this direcotry"
    rm -rf "${HOME}/${CLI_VENV_DIR}" 
fi
 
virtualenv -p /usr/bin/python3 "${HOME}/${CLI_VENV_DIR}" 
. ${HOME}/${CLI_VENV_DIR}/bin/activate
pip3 install --upgrade pip
pip3 install ansible
pip3 install dnspython
deactivate

log_info "Installed a CLI Python venv at ${HOME}/${CLI_VENV_DIR}"


# Create CLI env file
# ===================

log_info "Creating a CLI env file"

# Decide where to put the CLI env file
# Preferrably in ${HOME}/bin else in ${HOME}/.bin if it exists or create ${HOME}/bin as a last resort


if [ -d ${HOME}/bin ]
then
   CLI_ENV_FILE=${HOME}/bin/${CLI_ENV_FILE_NAME} 
elif [ -d ${HOME}/.bin ]
then
    CLI_ENV_FILE=${HOME}/.bin/${CLI_ENV_FILE_NAME}
else
    CLI_ENV_FILE=${HOME}/bin/${CLI_ENV_FILE_NAME}
    
    if [ ! -d ${HOME}/bin ]
    then
	mkdir ${HOME}/bin 
    fi 
fi



cat <<EOF > ${CLI_ENV_FILE}
#!/usr/bin/env bash

pushd ~

if [ -d ${CLI_VENV_DIR} ]
then
    . ${CLI_VENV_DIR}/bin/activate
fi



if ! ssh-add -l &>/dev/null
then
   # We are running in a shell without ssh-agent
   eval \`ssh-agent -s\`
   ssh-add .ssh/id_rsa
fi

popd

EOF


chmod 600 ${CLI_ENV_FILE}

log_info "CLI env file created in ${CLI_ENV_FILE}"

