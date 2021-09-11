#!/usr/bin/env bash

#  Copyright 2012-2021 Stanislav Senotrusov <stan@senotrusov.com>
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

if declare -f sopka::add-menu-item >/dev/null; then
  sopka::add-menu-item workstation::merge-editor-configs || fail
fi

workstation::merge-editor-configs() {
  vscode::merge-config || fail
  sublime::merge-config || fail
}

workstation::configure-git() {
  git config --global user.name "${MY_GIT_USER_NAME}" || fail
  git config --global user.email "${MY_GIT_USER_EMAIL}" || fail
  git config --global core.autocrlf input || fail
}

workstation::install-ssh-keys() {
  bitwarden::write-notes-to-file-if-not-exists "my ssh private key" "${HOME}/.ssh/id_ed25519" "077" || fail
  bitwarden::write-notes-to-file-if-not-exists "my ssh public key" "${HOME}/.ssh/id_ed25519.pub" "077" || fail
}
