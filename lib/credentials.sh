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

workstation::deploy::credentials() {
  # install gpg keys
  workstation::install_gpg_keys || fail

  # import password store
  workstation::pass::import_offline_to_local || fail

  # ssh key
  workstation::install_ssh_keys || fail

  # git
  workstation::configure_git_user || fail
  workstation::configure_git_signing_key || fail
  workstation::configure_git_credentials || fail

  # rubygems
  workstation::install_rubygems_credentials || fail

  # npm
  workstation::install_npm_credentials || fail

  # sublime text license
  workstation::sublime_text::install_license || fail

  # sublime merge license
  # workstation::sublime_merge::install_license || fail
}

workstation::install_gpg_keys() {
  gpg::import_key_with_ultimate_ownertrust "${MY_GPG_KEY}" "${MY_GPG_OFFLINE_KEY_FILE}" || fail
}

workstation::install_ssh_keys() {
  ssh::install_ssh_key_from_pass "${MY_SSH_KEY_PATH}" || fail
}

workstation::configure_git_user() {
  git config --global user.name "${MY_GIT_USER_NAME}" || fail
  git config --global user.email "${MY_GIT_USER_EMAIL}" || fail
}

workstation::configure_git_signing_key() {
  git::configure_signing_key "${MY_GPG_SIGNING_KEY}!" || fail
}

workstation::configure_git_credentials() {
  if [[ "${OSTYPE}" =~ ^linux ]]; then
    git::use_libsecret_credential_helper || fail
    pass::use "${MY_GITHUB_ACCESS_TOKEN_PATH}" git::gnome_keyring_credentials "${MY_GITHUB_LOGIN}" || fail
  fi
}

workstation::install_rubygems_credentials() {
  dir::make_if_not_exists "${HOME}/.gem" 755 || fail
  pass::use "${MY_RUBYGEMS_CREDENTIALS_PATH}" rubygems::credentials || fail
}

workstation::install_npm_credentials() {(
  asdf::load_if_installed || fail
  pass::use "${MY_NPM_PUBLISH_TOKEN_PATH}" npm::auth_token || fail
)}

workstation::make_keys_directory_if_not_exists() {
  dir::make_if_not_exists_and_set_permissions "${MY_KEYS_PATH}" 700 || fail
}
