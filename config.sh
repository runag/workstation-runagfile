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


# Auth for git
export MY_GIT_USER_EMAIL="stan@senotrusov.com"
export MY_GIT_USER_NAME="Stanislav Senotrusov"
export MY_GITHUB_LOGIN="senotrusov"


# Secrets
export MY_KEYS_VOLUME="/media/${USER}/KEYS-DAILY"

export MY_BITWARDEN_API_KEY_PATH="${MY_KEYS_VOLUME}/keys/bitwarden/stan-api-key.sh.asc"
export MY_GPG_KEY="84C200370DF103F0ADF5028FF4D70B8640424BEA"
export MY_GPG_KEY_PATH="${MY_KEYS_VOLUME}/keys/gpg/${MY_GPG_KEY:(-8)}/${MY_GPG_KEY:(-8)}-secret-subkeys.asc"
export MY_RESTIC_PASSWORD_FILE="${MY_KEYS_VOLUME}/keys/restic/stan.restic-password.asc"


# Ruby & Node versions
export NODENV_VERSION="16.13.0"
export RBENV_VERSION="3.0.2"
