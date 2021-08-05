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

    if [ "${UPDATE_SECRETS:-}" = "true" ] || ! command -v tailscale >/dev/null || tailscale::is-logged-out; then
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
  ubuntu::lazy-install-secrets-dependencies || fail

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

  # install gpg key
  ubuntu-workstation::install-gpg-key "84C200370DF103F0ADF5028FF4D70B8640424BEA" || fail
  git::configure-signingkey "38F6833D4C62D3AF8102789772080E033B1F76B5!" || fail

  # install restic key
  ubuntu-workstation::install-restic-key "stan" || fail
}

ubuntu-workstation::deploy-host-folders-access() {
  ubuntu::lazy-install-secrets-dependencies || fail

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
  ubuntu::lazy-install-secrets-dependencies || fail

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
  ubuntu::lazy-install-secrets-dependencies || fail
  # backup::vm-home-to-host::setup || fail
}

ubuntu-workstation::install-gpg-key() {
  local key="$1"
  if ! gpg --list-keys "${key}" >/dev/null 2>&1; then
    local keysVolume="/media/${USER}/KEYS-DAILY"
    mount::ask-for-mount "${keysVolume}" || fail

    gpg --import "${keysVolume}/keys/gpg/${key:(-8)}/${key:(-8)}-secret-subkeys.asc" || fail
    echo "${key}:6:" | gpg --import-ownertrust || fail
  fi
}

ubuntu-workstation::install-restic-key() {
  local key="$1"
  if [ ! -f "${HOME}/.keys/restic/${key}.txt" ]; then
    local keysVolume="/media/${USER}/KEYS-DAILY"
    mount::ask-for-mount "${keysVolume}" || fail
    
    gpg --decrypt "${keysVolume}/keys/restic/${key}.txt.asc" | restic::write-key "${key}"
    test "${PIPESTATUS[*]}" = "0 0" || fail
  fi
}
