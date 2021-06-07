#!/usr/bin/env bash

#  Copyright 2012-2019 Stanislav Senotrusov <stan@senotrusov.com>
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

windows::deploy-workstation() {
  # shell aliases
  shellrcd::install || fail
  shellrcd::use-nano-editor || fail
  shellrcd::sopka-path || fail
  bitwarden::shellrcd::set-bitwarden-login || fail

  # git
  git::configure || fail
  git::configure-user || fail

  # vscode
  vscode::install-config || fail
  vscode::install-extensions "${SOPKAFILE_DIR}/lib/vscode/extensions.txt" || fail

  # sublime text config
  sublime::install-config || fail

  # secrets
  if [ -t 0 ]; then
    (
      # add ssh key
      # bitwarden-object: "my ssh private key", "my ssh public key"
      ssh::install-keys "my" || fail

      # rubygems
      # bitwarden-object: "my rubygems credentials"
      bitwarden::write-notes-to-file-if-not-exists "my rubygems credentials" "${HOME}/.gem/credentials" || fail

      # sublime text license
      sublime::install-license || fail
    ) || fail
  fi

  touch "${HOME}/.sopka.workstation.deployed" || fail
}
