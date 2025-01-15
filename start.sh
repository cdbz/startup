#!/bin/bash

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

backup_configs

UPDATE_DIR="/tmp/update_$(date +%s)"
mkdir -p "$UPDATE_DIR"

GIT_ADDRESS="https://${USERNAME}:${ACCESS_TOKEN}@$(echo -e ${GIT_ADDRESS} | cut -d/ -f3-)"
if [ -z ${BRANCH} ]; then
    git clone ${GIT_ADDRESS} "$UPDATE_DIR"
else
    git clone --single-branch --branch ${BRANCH} ${GIT_ADDRESS} "$UPDATE_DIR"
fi

rsync -a --delete \
    --exclude 'config.json' \
    --exclude 'config/' \
    --exclude '.env' \
    "$UPDATE_DIR/" .

rm -rf "$UPDATE_DIR"
restore_configs

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