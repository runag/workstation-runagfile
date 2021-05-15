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
  apt::lazy-update || fail
  apt::dist-upgrade || fail

  # install open-vm-tools
  if vmware::linux::is-inside-vm; then
    apt::install open-vm-tools || fail
  fi

  # deploy sshd
  ubuntu::deploy-sshd || fail

  # perform cleanup
  apt::autoremove || fail
}

ubuntu::deploy-sshd() {
  # install and configure sshd
  sshd::ubuntu::install-and-configure || fail

  # import ssh key
  ssh-import-id gh:senotrusov || fail
}

ubuntu::deploy-my-folder-access() {
  # perform apt update and upgrade
  apt::lazy-update || fail

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
    ubuntu::mount-my-folder || fail
  ) || fail
}

ubuntu::deploy-workstation() {
  # disable screen lock
  ubuntu::desktop::disable-screen-lock || fail

  # update and upgrade
  apt::lazy-update || fail
  apt::dist-upgrade || fail

  # deploy minimal application server
  ubuntu::deploy-minimal-application-server || fail

  # increase inotify limits
  linux::set-inotify-max-user-watches || fail

  # gnome-keyring and libsecret (for git and ssh)
  ubuntu::packages::install-gnome-keyring-and-libsecret || fail

  # shellrcd
  shellrcd::install || fail
  shellrcd::sopka-path || fail

  # bitwarden cli
  bitwarden::shellrcd::set-bitwarden-login || fail
  bitwarden::install-cli || fail

  # vscode
  vscode::install-and-configure || fail

  # sublime text and sublime merge
  sublime::ubuntu::install-merge-and-text || fail

  # meld
  apt::install meld || fail

  # chromium
  sudo snap install chromium || fail

  # bitwarden
  sudo snap install bitwarden || fail

  # gparted
  apt::install gparted || fail

  # copyq
  # TODO: Check later
  # ubuntu::packages::install-copyq || fail

  # install rclone
  tools::install-rclone || fail

  # whois
  apt::install whois || fail

  # install cifs-utils
  apt::install cifs-utils || fail

  # install restic
  apt::install restic || fail

  if vmware::linux::is-inside-vm; then
    # open-vm-tools
    apt::install open-vm-tools open-vm-tools-desktop || fail
  fi

  # software for bare metal workstation
  if linux::is-bare-metal; then
    ubuntu::packages::install-obs-studio || fail

    apt::install ddccontrol gddccontrol ddccontrol-db i2c-tools || fail

    sudo snap install telegram-desktop || fail
    sudo snap install skype --classic || fail
    sudo snap install discord || fail
  fi

  # configure desktop
  ubuntu::desktop::configure || fail

  # configure git
  git::configure || fail
  git::configure-user || fail

  # install sublime configuration
  sublime::install-config || fail

  # enable systemd user instance without the need for the user to login
  systemd::enable-linger || fail

  # secrets
  if [ -t 1 ]; then
    # the following commands use bitwarden, that requires password entry
    # subshell for unlocked bitwarden
    (
      # secrets
      ubuntu::workstation::deploy-secrets || fail

      # mount host folder
      if vmware::linux::is-inside-vm; then
        ubuntu::mount-my-folder || fail
      fi
    ) || fail
  fi

  if vmware::linux::is-inside-vm; then
    backup::vm-home-to-host::setup || fail
  fi

  # cleanup
  apt::autoremove || fail

  # set "deployed" flag
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

  # install sublime license key
  sublime::install-license || fail
}

ubuntu::mount-my-folder() {
  local hostIpAddress; hostIpAddress="$(vmware::linux::get-host-ip-address)" || fail

  # bitwarden-object: "my microsoft account"
  fs::mount-cifs "//${hostIpAddress}/Users/${USER}/my" "my" "my microsoft account" || fail
}

backup::vm-home-to-host::load-configuration() {
  local machineUuid="$(vmware::get-machine-uuid)" || fail

  export BACKUP_NAME="vm-home-to-host"
  export RESTIC_REPOSITORY="${HOME}/my/storage/vm-home-backups/${machineUuid}"
  export RESTIC_PASSWORD="null"
}

backup::vm-home-to-host() {
  backup::vm-home-to-host::load-configuration || fail
  "$@" || fail
}

backup::vm-home-to-host::setup() (
  fs::sudo-write-file "/etc/sudoers.d/dmidecode" 0440 root <<SHELL || fail
${USER} ALL=NOPASSWD: /usr/sbin/dmidecode
SHELL

  backup::vm-home-to-host::load-configuration || fail

  # install systemd service
  declare -A serviceOptions
  serviceOptions[NoNewPrivileges]=false
  restic::systemd::init-service serviceOptions || fail

  # enable timer
  declare -A timerOptions
  timerOptions[OnCalendar]="*:00/30"
  timerOptions[RandomizedDelaySec]="300"
  restic::systemd::enable-timer timerOptions || fail
)

backup::vm-home-to-host::create() (
  backup::vm-home-to-host::load-configuration || fail

  # I should probably make a special user service to wait until the network is up and the directory is mounted
  findmnt -M "${HOME}/my" >/dev/null || fail

  if [ ! -d "${RESTIC_REPOSITORY}" ]; then
    restic::init || fail
  fi

  # The purpose of this is to have relative paths in backup
  cd "${HOME}" || fail

  local quietMaybe=""; test -t 1 || quietMaybe="--quiet"

  restic backup $quietMaybe --one-file-system . || fail

  tools::once-per-day backup::vm-home-to-host::forget-and-check || fail
)

backup::vm-home-to-host::forget-and-check() {
  backup::vm-home-to-host::load-configuration || fail

  restic::forget-and-prune || fail
  restic::check-and-read-data || fail
}
