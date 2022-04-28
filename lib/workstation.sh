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
  sopka_menu::add workstation::remove_nodejs_and_ruby_installations || fail
  sopka_menu::add workstation::edit_sopka_and_sopkafile || fail
  sopka_menu::add workstation::merge_editor_configs || fail
  sopka_menu::add_delimiter || fail
fi

workstation::edit_sopka_and_sopkafile() {
  local self_dir; self_dir="$(dirname "${BASH_SOURCE[0]}")" || fail
  local repo_dir; repo_dir="$(cd "${self_dir}/.." >/dev/null 2>&1 && pwd)" || fail

  code "${repo_dir}/sopka.code-workspace"
  smerge "${HOME}/.sopka"
  sleep 5
  smerge "${repo_dir}"
}

workstation::merge_editor_configs() {
  workstation::vscode::merge_config || fail
  workstation::sublime_merge::merge_config || fail
  workstation::sublime_text::merge_config || fail
}

workstation::configure_git() {
  git config --global core.autocrlf input || fail
}

workstation::configure_git_user() {
  git config --global user.name "${MY_GIT_USER_NAME}" || fail
  git config --global user.email "${MY_GIT_USER_EMAIL}" || fail
}

workstation::install_ssh_keys() {
  ssh::make_user_config_dir_if_not_exists || fail
  bitwarden::write_notes_to_file_if_not_exists "${MY_SSH_PRIVATE_KEY_ID}" "${HOME}/.ssh/id_ed25519" || fail
  bitwarden::write_notes_to_file_if_not_exists "${MY_SSH_PUBLIC_KEY_ID}" "${HOME}/.ssh/id_ed25519.pub" || fail
}

workstation::install_rubygems_credentials() {
  dir::make_if_not_exists "${HOME}/.gem" 755 || fail
  bitwarden::write_notes_to_file_if_not_exists "${MY_RUBYGEMS_CREDENTIALS_ID}" "${HOME}/.gem/credentials" || fail
}

workstation::install_npm_credentials() {
  nodenv::load_shellrc || fail
  bitwarden::use password "${MY_NPM_PUBLISH_TOKEN_ID}" npm::auth_token || fail
}

workstation::make_keys_directory_if_not_exists() {
  dir::make_if_not_exists_and_set_permissions "${HOME}/.keys" 700 || fail
}

workstation::remove_nodejs_and_ruby_installations() {
  rm -rf "${HOME}/.nodenv/versions"/* || fail
  rm -rf "${HOME}/.rbenv/versions"/* || fail
  rm -rf "${HOME}/.cache/yarn" || fail
  rm -rf "${HOME}/.solargraph" || fail
  rm -rf "${HOME}/.bundle" || fail
  rm -rf "${HOME}/.node-gyp" || fail
}
