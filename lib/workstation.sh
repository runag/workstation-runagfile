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

if declare -f sopka_menu::add >/dev/null; then
  sopka_menu::add_header Miscellaneous || fail
  sopka_menu::add workstation::remove-nodejs-and-ruby-installations || fail
  sopka_menu::add workstation::edit-sopka-and-sopkafile || fail
  sopka_menu::add workstation::merge-editor-configs || fail
  sopka_menu::add_delimiter || fail
fi

workstation::edit-sopka-and-sopkafile() {
  code "${HOME}/.sopka/sopkafiles/github-senotrusov-sopkafile/sopka.code-workspace"
  smerge "${HOME}/.sopka"
  sleep 3
  smerge "${HOME}/.sopka/sopkafiles/github-senotrusov-sopkafile"
}

workstation::merge-editor-configs() {
  workstation::vscode::merge-config || fail
  workstation::sublime_merge::merge-config || fail
  workstation::sublime_text::merge-config || fail
}

workstation::configure-git() {
  git config --global core.autocrlf input || fail
}

workstation::configure-git-user() {
  git config --global user.name "${MY_GIT_USER_NAME}" || fail
  git config --global user.email "${MY_GIT_USER_EMAIL}" || fail
}

workstation::install-ssh-keys() {
  ssh::make_user_config_dir_if_not_exists || fail
  bitwarden::write_notes_to_file_if_not_exists "my ssh private key" "${HOME}/.ssh/id_ed25519" || fail
  bitwarden::write_notes_to_file_if_not_exists "my ssh public key" "${HOME}/.ssh/id_ed25519.pub" || fail
}

workstation::install-rubygems-credentials() {
  dir::make_if_not_exists "${HOME}/.gem" 755 || fail
  bitwarden::write_notes_to_file_if_not_exists "my rubygems credentials" "${HOME}/.gem/credentials" || fail
}

workstation::install-npm-credentials() {
  nodenv::load_shellrc || fail
  bitwarden::use password "my npm publish token" npm::auth_token || fail
}

workstation::make-keys-directory-if-not-exists() {
  dir::make_if_not_exists_and_set_permissions "${HOME}/.keys" 700 || fail
}

workstation::remove-nodejs-and-ruby-installations() {
  rm -rf "${HOME}/.nodenv/versions"/* || fail
  rm -rf "${HOME}/.rbenv/versions"/* || fail
  rm -rf "${HOME}/.cache/yarn" || fail
  rm -rf "${HOME}/.solargraph" || fail
  rm -rf "${HOME}/.bundle" || fail
  rm -rf "${HOME}/.node-gyp" || fail
}
