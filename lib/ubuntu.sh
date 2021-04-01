#!/usr/bin/env bash

#  Copyright 2012-2020 Stanislav Senotrusov <stan@senotrusov.com>
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

ubuntu::deploy-minimal-local-vm-server() {
  # perform apt update and upgrade
  apt::update || fail
  apt::dist-upgrade || fail

  # install open-vm-tools
  if vmware::linux::is-inside-vm; then
    apt::install open-vm-tools || fail
  fi

  ubuntu::deploy-sshd || fail

  # perform cleanup
  apt::autoremove || fail
}

ubuntu::deploy-sshd() {
  sshd::ubuntu::install-and-configure || fail

  # import ssh key
  ssh-import-id gh:senotrusov || fail
}

ubuntu::deploy-host-documents-access() {
  # perform apt update and upgrade
  apt::update || fail

  # install cifs-utils
  apt::install cifs-utils || fail

  # shellrcd
  shellrcd::install || fail

  # install nodejs
  nodejs::ubuntu::install || fail

  # install bitwarden
  bitwarden::install-cli || fail

  # the following commands use bitwarden, that requires password entry
  # subshell for unlocked bitwarden
  (
    # mount host folder
    ubuntu::perhaps-mount-host-documents || fail
  ) || fail
}

ubuntu::deploy-workstation() {
  # disable screen lock
  ubuntu::desktop::disable-screen-lock || fail

  # update and upgrade
  apt::update || fail
  apt::dist-upgrade || fail

  # increase inotify limits
  linux::set-inotify-max-user-watches || fail

  # basic tools, contains curl so it have to be first
  ubuntu::packages::install-basic-tools || fail

  # devtools
  ubuntu::packages::install-devtools || fail

  # gnome-keyring and libsecret (for git and ssh)
  ubuntu::packages::install-gnome-keyring-and-libsecret || fail

  # shellrcd
  shellrcd::install || fail
  shellrcd::use-nano-editor || fail
  shellrcd::sopka-path || fail
  shellrcd::hook-direnv || fail

  # install ruby
  ruby::ubuntu::install || fail

  # install nodejs
  nodejs::ubuntu::install || fail

  # bitwarden cli
  bitwarden::shellrcd::set-bitwarden-login || fail
  bitwarden::install-cli || fail

  # vscode
  vscode::snap::install || fail
  vscode::install-config || fail
  vscode::install-extensions "${SOPKAFILE_DIR}/lib/vscode/extensions.txt" || fail

  # sublime text and sublime merge
  sublime::apt::add-sublime-source || fail
  apt::update || fail
  sublime::apt::install-sublime-merge || fail
  sublime::apt::install-sublime-text || fail

  # meld
  apt::install meld || fail

  # chromium
  sudo snap install chromium || fail

  # bitwarden
  sudo snap install bitwarden || fail

  # gparted
  apt::install gparted || fail

  if vmware::linux::is-inside-vm; then
    # open-vm-tools
    apt::install open-vm-tools open-vm-tools-desktop || fail

    # mount hgfs
    # vmware::linux::add-hgfs-automount || fail
    # vmware::linux::symlink-hgfs-mounts || fail
  fi

  # whois
  apt::install whois || fail

  # software for bare metal workstation
  if linux::is-bare-metal; then
    apt::add-obs-studio-source || fail
    apt::update || fail
    apt::install obs-studio guvcview || fail
    apt::install ddccontrol gddccontrol ddccontrol-db i2c-tools || fail

    sudo snap install telegram-desktop || fail
    sudo snap install skype --classic || fail
    sudo snap install discord || fail
  fi

  # install rclone
  tools::install-rclone || fail

  # configure desktop
  ubuntu::desktop::configure || fail

  # deploy sshd
  ubuntu::deploy-sshd || fail

  # configure git
  git::configure || fail
  git::configure-user || fail

  # install cifs-utils
  apt::install cifs-utils || fail

  # the following commands use bitwarden, that requires password entry
  # subshell for unlocked bitwarden
  (
    # secrets
    ubuntu::workstation::deploy-secrets || fail

    # mount host folder
    ubuntu::perhaps-mount-host-documents || fail
  ) || fail
 
  # cleanup
  apt::autoremove || fail

  touch "${HOME}/.sopka.workstation.deployed" || fail

  # display footnotes if running on interactive terminal
  tools::perhaps-display-deploy-footnotes || fail
}

ubuntu::workstation::deploy-secrets() {
  # install ssh key, configure ssh to use it
  # bitwarden-object: "my ssh private key", "my ssh public key"
  ssh::install-keys "my" || fail
  # bitwarden-object: "my password for ssh private key"
  ssh::ubuntu::add-key-password-to-keyring "my" || fail

  # git access token
  # bitwarden-object: "my github personal access token"
  git::ubuntu::add-credentials-to-keyring "my" || fail

  # rubygems
  # bitwarden-object: "my rubygems credentials"
  bitwarden::write-notes-to-file-if-not-exists "my rubygems credentials" "${HOME}/.gem/credentials" || fail

  # install sublime license key and configuration
  sublime::install-config || fail
}

ubuntu::perhaps-mount-host-documents() {
  if vmware::linux::is-inside-vm; then
    local hostIpAddress; hostIpAddress="$(vmware::linux::get-host-ip-address)" || fail

    # bitwarden-object: "my microsoft account"
    fs::mount-cifs "//${hostIpAddress}/Users/${USER}/Documents" "host-documents" "my microsoft account" || fail
  fi
}
