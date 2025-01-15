backup_configs() {
    if [ -f config.json ]; then
        cp config.json config.json.backup
    fi
    if [ -f .env ]; then
        cp .env .env.backup
    fi
    if [ -d config ]; then
        cp -r config config.backup
    fi
}

restore_configs() {
    if [ -f config.json.backup ]; then
        mv config.json.backup config.json
    fi
    if [ -f .env.backup ]; then
        mv .env.backup .env
    fi
    if [ -d config.backup ]; then
        rm -rf config
        mv config.backup config
    fi
}

cleanup_git() {
    if [ -d .git ]; then
        rm -rf .git
    fi
}

if [[ ! -d .git ]]; then
    backup_configs
    
    GIT_ADDRESS="https://${USERNAME}:${ACCESS_TOKEN}@$(echo -e ${GIT_ADDRESS} | cut -d/ -f3-)"
    if [ -z ${BRANCH} ]; then
        git clone ${GIT_ADDRESS} .
    else
        git clone --single-branch --branch ${BRANCH} ${GIT_ADDRESS} .
    fi
    
    restore_configs
    cleanup_git
elif [[ ${AUTO_UPDATE} == "1" ]]; then
    backup_configs
    
    mkdir -p /tmp/update
    GIT_ADDRESS="https://${USERNAME}:${ACCESS_TOKEN}@$(echo -e ${GIT_ADDRESS} | cut -d/ -f3-)"
    if [ -z ${BRANCH} ]; then
        git clone ${GIT_ADDRESS} /tmp/update
    else
        git clone --single-branch --branch ${BRANCH} ${GIT_ADDRESS} /tmp/update
    fi
    
    rsync -av --exclude 'config.json' --exclude 'config/' --exclude '.env' /tmp/update/ .
    
    rm -rf /tmp/update
fi

if [[ ! -z ${NODE_PACKAGES} ]]; then
    /usr/local/bin/npm install ${NODE_PACKAGES}
fi

if [[ ! -z ${UNNODE_PACKAGES} ]]; then
    /usr/local/bin/npm uninstall ${UNNODE_PACKAGES}
fi

if [ -f /home/container/package.json ]; then
    /usr/local/bin/npm install
fi

if [[ "${MAIN_FILE}" == "*.js" ]]; then
    /usr/local/bin/node "/home/container/${MAIN_FILE}" ${NODE_ARGS}
else
    /usr/local/bin/ts-node --esm "/home/container/${MAIN_FILE}" ${NODE_ARGS}
fi