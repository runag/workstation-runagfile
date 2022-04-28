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


# Auth
export SOPKA_AUTH_DEPLOY_LIST="backup bitwarden git github gpg npm rubygems ssh sublime_text_3 tailscale windows_cifs"


# Git auth
export MY_GIT_USER_EMAIL="stan@senotrusov.com"
export MY_GIT_USER_NAME="Stanislav Senotrusov"
export MY_GITHUB_LOGIN="senotrusov"


# GPG key
export MY_GPG_KEY="84C200370DF103F0ADF5028FF4D70B8640424BEA"
export MY_GPG_SIGNING_KEY="38F6833D4C62D3AF8102789772080E033B1F76B5"


# Key paths
if [[ "${OSTYPE}" =~ ^msys ]]; then
  export MY_KEYS_PATH="/k/keys"
elif [[ "${OSTYPE}" =~ ^darwin ]]; then
  export MY_KEYS_PATH="/Volumes/KEYS-DAILY/keys"
elif [[ "${OSTYPE}" =~ ^linux ]]; then
  export MY_KEYS_PATH="/media/${USER}/KEYS-DAILY/keys"
fi

export MY_GPG_KEY_FILE="${MY_KEYS_PATH}/gpg/workstation/secret-subkeys.asc"
export MY_BITWARDEN_API_KEY_FILE="${MY_KEYS_PATH}/bitwarden/workstation.sh.asc"
export MY_RESTIC_PASSWORD_FILE="${MY_KEYS_PATH}/restic/workstation.txt.asc"


# Bitwarden objects
export MY_DATA_SERVER_SSH_DESTINATION_ID="my data server ssh destination" # password
export MY_DATA_SERVER_SSH_PRIVATE_KEY_ID="my data server ssh private key" # notes
export MY_DATA_SERVER_SSH_PUBLIC_KEY_ID="my data server ssh public key" # password
export MY_GITHUB_ACCESS_TOKEN_ID="my github access token" # password
export MY_NPM_PUBLISH_TOKEN_ID="my npm publish token" # password
export MY_RUBYGEMS_CREDENTIALS_ID="my rubygems credentials" # notes
export MY_SSH_KEY_PASSWORD_ID="my ssh key password" # password
export MY_SSH_PRIVATE_KEY_ID="my ssh private key" # notes
export MY_SSH_PUBLIC_KEY_ID="my ssh public key" # password
export MY_SUBLIME_MERGE_LICENSE_ID="my sublime merge license" # notes
export MY_SUBLIME_TEXT_3_LICENSE_ID="my sublime text 3 license" # notes
export MY_TAILSCALE_REUSABLE_KEY_ID="my tailscale reusable key" # password
export MY_WINDOWS_CIFS_CREDENTIALS_ID="my windows cifs credentials" # username, password

# Ruby & Node versions
export NODENV_VERSION="16.13.0"
export RBENV_VERSION="3.0.2"
