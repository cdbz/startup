#!/bin/bash

# Funktionen für Backup und Restore
backup_configs() {
    mkdir -p /tmp/backups
    if [ -f config.json ]; then
        cp config.json /tmp/backups/
    fi
    if [ -f .env ]; then
        cp .env /tmp/backups/
    fi
    if [ -d config ]; then
        cp -r config /tmp/backups/
    fi
}

restore_configs() {
    if [ -d /tmp/backups ]; then
        cp -r /tmp/backups/* .
        rm -rf /tmp/backups
    fi
}

# Hauptlogik
if [ -f package.json ]; then
    # Update-Fall
    backup_configs
    
    # Alle Dateien außer Backups löschen
    find . -mindepth 1 -maxdepth 1 ! -name 'tmp' -exec rm -rf {} +
    
    # Neuen Code klonen
    GIT_ADDRESS="https://${USERNAME}:${ACCESS_TOKEN}@$(echo -e ${GIT_ADDRESS} | cut -d/ -f3-)"
    if [ -z ${BRANCH} ]; then
        git clone ${GIT_ADDRESS} .
    else
        git clone --single-branch --branch ${BRANCH} ${GIT_ADDRESS} .
    fi
    
    # Configs wiederherstellen
    restore_configs
else
    # Erstinstallation
    GIT_ADDRESS="https://${USERNAME}:${ACCESS_TOKEN}@$(echo -e ${GIT_ADDRESS} | cut -d/ -f3-)"
    if [ -z ${BRANCH} ]; then
        git clone ${GIT_ADDRESS} .
    else
        git clone --single-branch --branch ${BRANCH} ${GIT_ADDRESS} .
    fi
fi

# Git-Verzeichnis entfernen
rm -rf .git

# NPM Pakete Installation
if [[ ! -z ${NODE_PACKAGES} ]]; then
    /usr/local/bin/npm install ${NODE_PACKAGES}
fi

if [[ ! -z ${UNNODE_PACKAGES} ]]; then
    /usr/local/bin/npm uninstall ${UNNODE_PACKAGES}
fi

if [ -f /home/container/package.json ]; then
    /usr/local/bin/npm install
fi

# Starten der Anwendung
/usr/local/bin/npm run start