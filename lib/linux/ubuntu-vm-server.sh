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

ubuntu-vm-server::deploy() {
  # perform apt update and upgrade
  if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    apt::lazy-update || fail
  else
    apt::lazy-update-and-dist-upgrade || fail
  fi

  # install open-vm-tools
  if vmware::is-inside-vm; then
    apt::install open-vm-tools || fail
  fi

  # install and configure sshd
  echo "PasswordAuthentication no" | file::sudo-write "/etc/ssh/sshd_config.d/disable-password-authentication.conf" || fail
  apt::install openssh-server || fail
  sudo systemctl --now enable ssh || fail
  sudo systemctl reload ssh || fail

  # import ssh key
  apt::install ssh-import-id || fail
  ssh-import-id gh:senotrusov || fail

  # install avahi daemon
  apt::install avahi-daemon || fail

  # perform cleanup
  apt::autoremove || fail
}

ubuntu-vm-server::deploy-my-folder-access() {
  # perform apt update and upgrade
  apt::lazy-update || fail

  # install cifs-utils
  apt::install cifs-utils || fail

  # install nodejs
  nodejs::apt::install || fail

  # install bitwarden
  bitwarden::install-cli || fail

  # the following commands use bitwarden, that requires password entry
  # subshell for unlocked bitwarden
  (
    # mount host folder
    ubuntu-workstation::configure-my-folder-mount || fail
  ) || fail
}
