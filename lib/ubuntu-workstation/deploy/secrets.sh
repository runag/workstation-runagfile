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

# install gnome-keyring and libsecret, install and configure git libsecret-credential-helper
ubuntu-workstation::deploy-secrets::preliminary-stage(){
  apt::lazy_update || fail
  apt::install_gnome_keyring_and_libsecret || fail

  git::install_libsecret_credential_helper || fail
  git::use_libsecret_credential_helper || fail
}

ubuntu-workstation::deploy-secrets() {
  bitwarden::beyond_session task::run_with_install_filter ubuntu-workstation::deploy-secrets::preliminary-stage || fail

  # install gpg keys
  ubuntu-workstation::install-all-gpg-keys || fail

  # install bitwarden cli and login
  ubuntu-workstation::install-bitwarden-cli-and-login || fail

  # install ssh key, configure ssh  to use it
  workstation::install-ssh-keys || fail
  bitwarden::use password "my password for ssh private key" ssh::gnome_keyring_credentials || fail

  # git access token
  bitwarden::use password "my github personal access token" git::gnome_keyring_credentials "${MY_GITHUB_LOGIN}" || fail

  # rubygems
  workstation::install-rubygems-credentials || fail

  # npm
  workstation::install-npm-credentials || fail

  # install sublime license key
  workstation::sublime_text::install-license || fail

  # configure git to use gpg signing key
  git::configure_signingkey "38F6833D4C62D3AF8102789772080E033B1F76B5!" || fail

  log::success "Done ubuntu-workstation::deploy-secrets" || fail
}
