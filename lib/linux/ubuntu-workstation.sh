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

ubuntu-workstation::deploy-full-workstation() {
  ubuntu-workstation::deploy-workstation-base || fail
  ubuntu-workstation::deploy-secrets || fail
  ubuntu-workstation::deploy-host-folders-access || fail
  ubuntu-workstation::deploy-tailscale || fail
  ubuntu-workstation::deploy-backup || fail
}

ubuntu-workstation::deploy-workstation-base() {
  # disable screen lock
  gsettings set org.gnome.desktop.session idle-delay 0 || fail

  # perform cleanup
  apt::autoremove || fail

  # update and upgrade
  if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    apt::lazy-update || fail
  else
    apt::lazy-update-and-dist-upgrade || fail
  fi

  # install tools to use by the rest of the script
  apt::install-tools || fail

  # shellrc
  ubuntu-workstation::install-shellrc || fail

  # install system software
  ubuntu-workstation::install-system-software || fail

  # configure system
  ubuntu-workstation::configure-system || fail

  # install terminal software
  ubuntu-workstation::install-terminal-software || fail

  # configure git
  ubuntu-workstation::configure-git || fail

  # install build tools
  ubuntu-workstation::install-build-tools || fail

  # install and configure servers
  ubuntu-workstation::install-servers || fail
  ubuntu-workstation::configure-servers || fail

  # programming languages
  ubuntu-workstation::install-and-update-nodejs || fail
  ubuntu-workstation::install-and-update-ruby || fail
  ubuntu-workstation::install-and-update-python || fail

  # install & configure desktop software
  ubuntu-workstation::install-desktop-software || fail
  ubuntu-workstation::configure-desktop-software || fail

  # set "deployed" flag
  touch "${HOME}/.sopka.workstation.deployed" || fail

  # display footnotes if running on interactive terminal
  tools::perhaps-display-deploy-footnotes || fail
}

ubuntu-workstation::deploy-secrets() {
  # Check if we have terminal
  if [ ! -t 0 ]; then
    fail "Terminal input should be available"
  fi

  # perform apt update and upgrade
  apt::lazy-update || fail

  # install nodejs & bitwarden
  nodejs::apt::install || fail
  bitwarden::install-cli || fail

  # install gnome-keyring and libsecret (for git and ssh)
  apt::install-gnome-keyring-and-libsecret || fail
  git::install-libsecret-credential-helper || fail

  # install ssh key, configure ssh to use it
  # bitwarden-object: "my ssh private key", "my ssh public key"
  # bitwarden-object: "my password for ssh private key"
  ssh::install-keys "my" || fail
  ssh::add-key-password-to-gnome-keyring "my" || fail

  # git access token
  # bitwarden-object: "my github personal access token"
  git::add-credentials-to-gnome-keyring "my" || fail
  git::use-libsecret-credential-helper || fail

  # rubygems
  # bitwarden-object: "my rubygems credentials"
  bitwarden::write-notes-to-file-if-not-exists "my rubygems credentials" "${HOME}/.gem/credentials" || fail

  # install sublime license key
  sublime::install-license || fail
}

ubuntu-workstation::deploy-host-folders-access() (
  # Check if we have terminal
  if [ ! -t 0 ]; then
    fail "Terminal input should be available"
  fi

  # perform apt update and upgrade
  apt::lazy-update || fail

  # install nodejs & bitwarden
  nodejs::apt::install || fail
  bitwarden::install-cli || fail

  # install cifs-utils
  apt::install cifs-utils || fail

  # mount host folder
  ubuntu-workstation::configure-host-folders-mount || fail
)

ubuntu-workstation::deploy-tailscale() (
  # Check if we have terminal
  if [ ! -t 0 ]; then
    fail "Terminal input should be available"
  fi

  # perform apt update and upgrade
  apt::lazy-update || fail

  # install nodejs & bitwarden
  nodejs::apt::install || fail
  bitwarden::install-cli || fail

  # install tailscale
  tailscale::install || fail
  tailscale::install-issue-2541-workaround || fail

  ubuntu-workstation::configure-tailscale || fail
)

ubuntu-workstation::deploy-backup() (
  echo TODO
  # backup::vm-home-to-host::setup || fail
)
