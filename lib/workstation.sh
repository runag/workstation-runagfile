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

if declare -f sopka-menu::add >/dev/null; then
  sopka-menu::add workstation::merge-editor-configs || fail
  sopka-menu::add workstation::edit || fail
fi

edit() {
  workstation::edit || fail
}

workstation::edit() {
  code "${HOME}/.sopka/sopkafiles/github-senotrusov-sopkafile/sopka.code-workspace"
  smerge "${HOME}/.sopka"
  sleep 3
  smerge "${HOME}/.sopka/sopkafiles/github-senotrusov-sopkafile"
}

workstation::merge-editor-configs() {
  workstation::vscode::merge-config || fail
  workstation::sublime-merge::merge-config || fail
  workstation::sublime-text::merge-config || fail
}

workstation::configure-git() {
  git config --global user.name "${MY_GIT_USER_NAME}" || fail
  git config --global user.email "${MY_GIT_USER_EMAIL}" || fail
  git config --global core.autocrlf input || fail
}

workstation::install-ssh-keys() {
  ssh::make-user-config-directory-if-not-exists || fail
  bitwarden::write-notes-to-file-if-not-exists "my ssh private key" "${HOME}/.ssh/id_ed25519" || fail
  bitwarden::write-notes-to-file-if-not-exists "my ssh public key" "${HOME}/.ssh/id_ed25519.pub" || fail
}

workstation::install-rubygems-credentials() {
  dir::make-if-not-exists "${HOME}/.gem" 755 || fail
  bitwarden::write-notes-to-file-if-not-exists "my rubygems credentials" "${HOME}/.gem/credentials" || fail
}

workstation::install-npm-credentials() {
  nodejs::load-nodenv || fail
  bitwarden::use password "my npm publish token" nodejs::auth-token || fail
}

workstation::make-keys-directory-if-not-exists() {
  dir::make-if-not-exists-but-chmod-anyway "${HOME}/.keys" 700 || fail
}
