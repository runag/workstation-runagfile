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

  # subshell to deploy secrets
  (
    ubuntu-workstation::deploy-secrets || fail

    if vmware::is-inside-vm; then
      ubuntu-workstation::deploy-host-folders-access || fail
    fi

    if tailscale::is-logged-out; then
      ubuntu-workstation::deploy-tailscale || fail
    fi

    ubuntu-workstation::deploy-backup || fail
  ) || fail
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
}

ubuntu-workstation::deploy-secrets() {
  ubuntu::deploy-secrets-lazy-prerequisites || fail

  ( unset BW_SESSION
    # install gnome-keyring and libsecret (for git and ssh), configure git
    apt::install-gnome-keyring-and-libsecret || fail
    git::install-libsecret-credential-helper || fail
    git::use-libsecret-credential-helper || fail
  ) || fail

  # install ssh key, configure ssh to use it
  # bitwarden-object: "my ssh private key", "my ssh public key"
  # bitwarden-object: "my password for ssh private key"
  ssh::install-keys "my" || fail
  ssh::add-key-password-to-gnome-keyring "my" || fail

  # git access token
  # bitwarden-object: "my github personal access token"
  git::add-credentials-to-gnome-keyring "my" || fail

  # rubygems
  # bitwarden-object: "my rubygems credentials"
  bitwarden::write-notes-to-file-if-not-exists "my rubygems credentials" "${HOME}/.gem/credentials" || fail

  # install sublime license key
  sublime::install-license || fail
}

ubuntu-workstation::deploy-host-folders-access() {
  ubuntu::deploy-secrets-lazy-prerequisites || fail

  ( unset BW_SESSION
    # install cifs-utils
    apt::install cifs-utils || fail
  ) || fail

  # mount host folder
  local hostIpAddress; hostIpAddress="$(unset BW_SESSION && vmware::get-host-ip-address)" || fail

  # bitwarden-object: "my microsoft account"
  mount::cifs "//${hostIpAddress}/my" "my" "my microsoft account" || fail
  mount::cifs "//${hostIpAddress}/ephemeral-data" "ephemeral-data" "my microsoft account" || fail
}

ubuntu-workstation::deploy-tailscale() {
  ubuntu::deploy-secrets-lazy-prerequisites || fail

  # get tailscale key  
  # bitwarden-object: "my tailscale reusable key"
  bitwarden::unlock || fail
  local tailscaleKey; tailscaleKey="$(NODENV_VERSION=system bw get password "my tailscale reusable key")" || fail

  ( unset BW_SESSION
    # install tailscale
    tailscale::install || fail
    tailscale::install-issue-2541-workaround || fail

    # configure tailscale
    sudo tailscale up \
      --authkey "${tailscaleKey}" \
      || fail
  ) || fail
}

ubuntu-workstation::deploy-backup() {
  ubuntu::deploy-secrets-lazy-prerequisites || fail
  # backup::vm-home-to-host::setup || fail
}

ubuntu::deploy-secrets-lazy-prerequisites() {
  if [ -z "${SOPKA_DEPLOY_SECRETS_LAZY_PREREQUISITES_HAPPENED:-}" ]; then
    SOPKA_DEPLOY_SECRETS_LAZY_PREREQUISITES_HAPPENED=1
    ( unset BW_SESSION

      # Check if we have terminal
      if [ ! -t 0 ]; then
        fail "Terminal input should be available"
      fi

      # perform apt update and upgrade
      apt::lazy-update || fail

      # install nodejs & bitwarden
      nodejs::apt::install || fail
      bitwarden::install-cli || fail
    ) || fail
  fi
}
