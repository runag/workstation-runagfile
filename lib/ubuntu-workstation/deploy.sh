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
  if [ -n "${DISPLAY:-}" ]; then
    sopka::add-menu-item ubuntu-workstation::deploy-full-workstation || fail
    sopka::add-menu-item ubuntu-workstation::deploy-workstation-base || fail
    sopka::add-menu-item ubuntu-workstation::deploy-secrets || fail
  fi
  sopka::add-menu-item ubuntu-workstation::deploy-vm-server || fail
  if vmware::is-inside-vm; then
    sopka::add-menu-item ubuntu-workstation::deploy-host-folders-access || fail
  fi
  sopka::add-menu-item ubuntu-workstation::deploy-tailscale || fail
  sopka::add-menu-item ubuntu-workstation::deploy-shellrc || fail
  sopka::add-menu-item ubuntu-workstation::change-hostname || fail
fi

ubuntu-workstation::deploy-full-workstation() {
  ubuntu-workstation::deploy-workstation-base || fail

  # subshell to deploy secrets
  (
    ubuntu-workstation::deploy-secrets || fail

    if vmware::is-inside-vm; then
      ubuntu-workstation::deploy-host-folders-access || fail
    fi

    ubuntu-workstation::deploy-tailscale || fail
    ubuntu-workstation::backup::deploy || fail
  ) || fail
}

ubuntu-workstation::deploy-workstation-base() {
  # disable screen lock
  gsettings set org.gnome.desktop.session idle-delay 0 || fail

  # perform cleanup
  apt::autoremove || fail

  # update and upgrade
  apt::lazy-update || fail
  if [ "${GITHUB_ACTIONS:-}" != "true" ]; then
    apt::dist-upgrade || fail
  fi

  # install tools to use by the rest of the script
  apt::install-tools || fail

  # shellrc
  ubuntu-workstation::deploy-shellrc || fail

  # install system software
  ubuntu-workstation::install-system-software || fail

  # configure system
  ubuntu-workstation::configure-system || fail

  # install terminal software
  ubuntu-workstation::install-terminal-software || fail

  # configure git
  workstation::configure-git || fail

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
  ubuntu-workstation::deploy-bitwarden || fail

  # install gnome-keyring and libsecret, install and configure git libsecret-credential-helper
  (
    unset BW_SESSION

    apt::lazy-update || fail
    apt::install-gnome-keyring-and-libsecret || fail

    git::install-libsecret-credential-helper || fail
    git::use-libsecret-credential-helper || fail
  ) || fail

  # install ssh key, configure ssh  to use it
  workstation::install-ssh-keys || fail
  bitwarden::use password "my password for ssh private key" ssh::gnome-keyring-credentials || fail

  # git access token
  bitwarden::use password "my github personal access token" git::gnome-keyring-credentials "${MY_GITHUB_LOGIN}" || fail

  # rubygems
  bitwarden::write-notes-to-file-if-not-exists "my rubygems credentials" "${HOME}/.gem/credentials" || fail

  # install sublime license key
  sublime::install-license || fail

  # install gpg key
  ubuntu-workstation::install-all-gpg-keys || fail
  git::configure-signingkey "38F6833D4C62D3AF8102789772080E033B1F76B5!" || fail
}

ubuntu-workstation::deploy-host-folders-access() {
  ubuntu-workstation::deploy-bitwarden || fail

  # mount host folder
  local credentialsFile="${HOME}/.keys/my-microsoft-account.cifs-credentials"
  bitwarden::use username password "my microsoft account" mount::cifs::credentials "${credentialsFile}" || fail

  (
    unset BW_SESSION 
    local hostIpAddress; hostIpAddress="$(vmware::get-host-ip-address)" || fail

    apt::install cifs-utils || fail
    mount::cifs "//${hostIpAddress}/my" "${HOME}/my" "${credentialsFile}" || fail
    mount::cifs "//${hostIpAddress}/ephemeral-data" "${HOME}/ephemeral-data" "${credentialsFile}" || fail
  ) || fail
}

ubuntu-workstation::deploy-tailscale() {
  ubuntu-workstation::deploy-bitwarden || fail

  if [ "${SOPKA_UPDATE_SECRETS:-}" = true ] || ! command -v tailscale >/dev/null || tailscale::is-logged-out; then
    bitwarden::unlock-and-sync || fail
    local tailscaleKey; tailscaleKey="$(bw get password "my tailscale reusable key")" || fail

    (
      unset BW_SESSION

      # install tailscale
      if ! command -v tailscale >/dev/null; then
        tailscale::install || fail
        tailscale::install-issue-2541-workaround || fail
      fi

      # logout if SOPKA_UPDATE_SECRETS is set
      if [ "${SOPKA_UPDATE_SECRETS:-}" = true ] && ! tailscale::is-logged-out; then
        sudo tailscale logout || fail
      fi

      # configure tailscale
      sudo tailscale up --authkey "${tailscaleKey}" || fail

    ) || fail
  fi
}

ubuntu-workstation::deploy-vm-server() {
  # perform cleanup
  apt::autoremove || fail

  # perform apt update and upgrade
  apt::lazy-update || fail
  if [ "${GITHUB_ACTIONS:-}" != "true" ]; then
    apt::dist-upgrade || fail
  fi

  # install open-vm-tools
  if vmware::is-inside-vm; then
    apt::install open-vm-tools || fail
  fi

  # install and configure sshd
  sshd::disable-password-authentication || fail
  apt::install openssh-server || fail
  sudo systemctl --now enable ssh || fail
  sudo systemctl reload ssh || fail

  # import ssh key
  apt::install ssh-import-id || fail
  ssh-import-id gh:senotrusov || fail

  # install avahi daemon
  apt::install avahi-daemon || fail
}

ubuntu-workstation::deploy-shellrc() {
  shell::install-shellrc-directory-loader "${HOME}/.bashrc" || fail
  shell::install-sopka-path-shellrc || fail
  shell::install-nano-editor-shellrc || fail
}

ubuntu-workstation::deploy-bitwarden() {
  bitwarden::snap::install-cli || fail
  bitwarden::login "${MY_BITWARDEN_LOGIN}" || fail
}

ubuntu-workstation::change-hostname() {
  local hostname
  echo "Please enter new hostname:"
  IFS="" read -r hostname || fail

  linux::dangerously-set-hostname "${hostname}" || fail
}
