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

if [[ "${OSTYPE}" =~ ^linux ]] && declare -f sopka-menu::add >/dev/null; then
  if [ -n "${DISPLAY:-}" ]; then
    sopka-menu::add ubuntu-workstation::deploy-full-workstation || fail
    sopka-menu::add ubuntu-workstation::deploy-workstation-base || fail
    sopka-menu::add ubuntu-workstation::deploy-secrets || fail
  fi
  sopka-menu::add ubuntu-workstation::deploy-vm-server || fail
  if vmware::is-inside-vm; then
    sopka-menu::add ubuntu-workstation::deploy-host-folders-access || fail
  fi
  sopka-menu::add ubuntu-workstation::deploy-tailscale || fail
  sopka-menu::add ubuntu-workstation::deploy-shellrc || fail
  sopka-menu::add ubuntu-workstation::change-hostname || fail
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

  log::success "Done ubuntu-workstation::deploy-full-workstation" || fail
}

ubuntu-workstation::deploy-workstation-base() {
  # disable screen lock
  gsettings set org.gnome.desktop.session idle-delay 0 || fail

  # perform cleanup
  task::run apt::autoremove || fail

  # update and upgrade
  task::run apt::lazy-update || fail
  if [ "${GITHUB_ACTIONS:-}" != "true" ]; then
    task::run apt::dist-upgrade || fail
  fi

  # install tools to use by the rest of the script
  task::run apt::install-tools || fail

  # shellrc
  task::run ubuntu-workstation::install-shellrc || fail

  # install system software
  task::run ubuntu-workstation::install-system-software || fail

  # configure system
  task::run ubuntu-workstation::configure-system || fail

  # install terminal software
  task::run ubuntu-workstation::install-terminal-software || fail

  # configure git
  task::run workstation::configure-git || fail

  # install build tools
  task::run ubuntu-workstation::install-build-tools || fail

  # install and configure servers
  task::run ubuntu-workstation::install-servers || fail
  task::run ubuntu-workstation::configure-servers || fail

  # programming languages
  task::run ubuntu-workstation::install-and-update-nodejs || fail
  task::run-and-fail-on-error-in-rubygems ubuntu-workstation::install-and-update-ruby || fail
  task::run ubuntu-workstation::install-and-update-python || fail

  # install & configure desktop software
  task::run ubuntu-workstation::install-desktop-software::apt || fail
  if [ -n "${DISPLAY:-}" ]; then
    task::run ubuntu-workstation::configure-desktop-software || fail
  fi

  # possible interactive part (so without task::run)

  # install sublime merge configuration
  workstation::sublime-merge::install-config || fail

  # install sublime text configuration
  workstation::sublime-text::install-config || fail

  # snap stuff
  ubuntu-workstation::install-desktop-software::snap || fail

  log::success "Done ubuntu-workstation::deploy-workstation-base" || fail
}

# install gnome-keyring and libsecret, install and configure git libsecret-credential-helper
ubuntu-workstation::deploy-secrets::preliminary-stage(){
  apt::lazy-update || fail
  apt::install-gnome-keyring-and-libsecret || fail

  git::install-libsecret-credential-helper || fail
  git::use-libsecret-credential-helper || fail
}

ubuntu-workstation::deploy-secrets() {
  bitwarden::beyond-session task::run ubuntu-workstation::deploy-secrets::preliminary-stage || fail

  # install gpg keys
  ubuntu-workstation::install-all-gpg-keys || fail

  # install bitwarden cli and login
  ubuntu-workstation::install-bitwarden-cli-and-login || fail

  # install ssh key, configure ssh  to use it
  workstation::install-ssh-keys || fail
  bitwarden::use password "my password for ssh private key" ssh::gnome-keyring-credentials || fail

  # git access token
  bitwarden::use password "my github personal access token" git::gnome-keyring-credentials "${MY_GITHUB_LOGIN}" || fail

  # rubygems
  workstation::install-rubygems-credentials || fail

  # npm
  workstation::install-npm-credentials || fail

  # install sublime license key
  workstation::sublime-text::install-license || fail

  # configure git to use gpg signing key
  git::configure-signingkey "38F6833D4C62D3AF8102789772080E033B1F76B5!" || fail

  log::success "Done ubuntu-workstation::deploy-secrets" || fail
}

ubuntu-workstation::deploy-host-folders-access() {
  # install gpg keys
  ubuntu-workstation::install-all-gpg-keys || fail

  # install bitwarden cli and login
  ubuntu-workstation::install-bitwarden-cli-and-login || fail

  # mount host folder
  local credentialsFile="${HOME}/.keys/host-filesystem-access.cifs-credentials"

  workstation::make-keys-directory-if-not-exists || fail
  bitwarden::use username password "my workstation virtual machine host filesystem access credentials" cifs::credentials "${credentialsFile}" || fail

  bitwarden::beyond-session task::run-with-short-title ubuntu-workstation::deploy-host-folders-access::stage-2 "${credentialsFile}" || fail

  log::success "Done ubuntu-workstation::deploy-host-folders-access" || fail
}

ubuntu-workstation::deploy-host-folders-access::stage-2() {
  local credentialsFile="$1"

  local hostIpAddress; hostIpAddress="$(vmware::get-host-ip-address)" || fail

  apt::install cifs-utils || fail
  cifs::mount "//${hostIpAddress}/my" "${HOME}/my" "${credentialsFile}" || fail
  cifs::mount "//${hostIpAddress}/ephemeral-data" "${HOME}/ephemeral-data" "${credentialsFile}" || fail
}

ubuntu-workstation::deploy-tailscale() {
  # install gpg keys
  ubuntu-workstation::install-all-gpg-keys || fail

  # install bitwarden cli and login
  ubuntu-workstation::install-bitwarden-cli-and-login || fail

  if [ "${SOPKA_UPDATE_SECRETS:-}" = true ] || ! command -v tailscale >/dev/null || tailscale::is-logged-out; then
    bitwarden::unlock-and-sync || fail
    local tailscaleKey; tailscaleKey="$(bw get password "my tailscale reusable key")" || fail
    bitwarden::beyond-session task::run-with-short-title ubuntu-workstation::deploy-tailscale::stage-2 "${tailscaleKey}" || fail
  fi

  log::success "Done ubuntu-workstation::deploy-tailscale" || fail
}

ubuntu-workstation::deploy-tailscale::stage-2() {
  local tailscaleKey="$1"

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

  log::success "Done ubuntu-workstation::deploy-vm-server" || fail
}

ubuntu-workstation::deploy-shellrc() {
  ubuntu-workstation::install-shellrc || fail

  log::success "Done ubuntu-workstation::deploy-shellrc" || fail
}

ubuntu-workstation::change-hostname() {
  local hostname
  echo "Please enter new hostname:"
  IFS="" read -r hostname || fail

  linux::dangerously-set-hostname "${hostname}" || fail

  log::success "Done ubuntu-workstation::change-hostname" || fail
}
