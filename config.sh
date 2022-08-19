#!/usr/bin/env bash

#  Copyright 2012-2022 Stanislav Senotrusov <stan@senotrusov.com>
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.


# Git
export MY_GIT_USER_EMAIL="stan@senotrusov.com"
export MY_GIT_USER_NAME="Stanislav Senotrusov"

# Github
export MY_GITHUB_LOGIN="senotrusov"

# Key paths
export MY_KEYS_PATH="${HOME}/.keys"

if [[ "${OSTYPE}" =~ ^msys ]]; then
  export MY_KEYS_OFFLINE_PATH="/k/keys"
elif [[ "${OSTYPE}" =~ ^darwin ]]; then
  export MY_KEYS_OFFLINE_PATH="/Volumes/KEYS-DAILY/keys"
elif [[ "${OSTYPE}" =~ ^linux ]]; then
  export MY_KEYS_OFFLINE_PATH="/media/${USER}/KEYS-DAILY/keys"
fi

# GPG key
export MY_GPG_KEY="84C200370DF103F0ADF5028FF4D70B8640424BEA"
export MY_GPG_SIGNING_KEY="38F6833D4C62D3AF8102789772080E033B1F76B5"
export MY_GPG_OFFLINE_KEY_FILE="${MY_KEYS_OFFLINE_PATH}/gpg/workstation/secret-subkeys.asc"

# Password store
export MY_PASSWORD_STORE_OFFLINE_PATH="${MY_KEYS_OFFLINE_PATH}/password-store/workstation"

export MY_GITHUB_ACCESS_TOKEN_PATH="github/access-token" # password
export MY_NPM_PUBLISH_TOKEN_PATH="npm/publish-token" # password
export MY_PRIVATE_SOPKAFILES_LIST_PATH="sopka/private-sopkafiles" # ssh key
export MY_RUBYGEMS_CREDENTIALS_PATH="rubygems/credentials" # body
export MY_SSH_KEY_PATH="ssh/workstation/id_ed25519" # ssh key
export MY_SUBLIME_MERGE_LICENSE_PATH="sublime-merge/license" # body
export MY_SUBLIME_TEXT_LICENSE_PATH="sublime-text/license" # body
export MY_TAILSCALE_REUSABLE_KEY_PATH="tailscale/reusable-key" # password
export MY_WINDOWS_CIFS_CREDENTIALS_PATH="windows/cifs-credentials" # username, password
export MY_WORKSTATION_BACKUP_RESTIC_PASSWORD_PATH="restic/backup" # password
export MY_WORKSTATION_BACKUP_SSH_KEY_PATH="ssh/backup-server/id_ed25519_backup_server" # ssh key

# Ruby & Node versions
export RBENV_VERSION="3.1.2"

# Backup
export BACKUP_REMOTE_HOST="backup-server"
export BACKUP_REPOSITORY_NAME; BACKUP_REPOSITORY_NAME="workstation/$(os::hostname)" || fail

export BACKUP_REMOTE_PATH="backups/restic-data/${BACKUP_REPOSITORY_NAME}"
export BACKUP_MOUNT_POINT="${HOME}/backups/mounts/${BACKUP_REPOSITORY_NAME}"
export BACKUP_RESTORE_PATH="${HOME}/backups/restores/${BACKUP_REPOSITORY_NAME}"

export BACKUP_RESTIC_PASSWORD_FILE="${MY_KEYS_PATH}/restic/backup"
export BACKUP_RESTIC_REPOSITORY="sftp:${BACKUP_REMOTE_HOST}:${BACKUP_REMOTE_PATH}"
