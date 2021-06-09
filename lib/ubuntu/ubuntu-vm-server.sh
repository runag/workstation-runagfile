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

ubuntu-vm-server::deploy() {
  # perform apt update and upgrade
  apt::lazy-update-and-dist-upgrade || fail

  # install open-vm-tools
  if vmware::is-inside-vm; then
    apt::install open-vm-tools || fail
  fi

  # install and configure sshd
  sshd::ubuntu::install-and-configure || fail

  # import ssh key
  ssh-import-id gh:senotrusov || fail

  # perform cleanup
  apt::autoremove || fail
}

ubuntu-vm-server::deploy-my-folder-access() {
  # perform apt update and upgrade
  apt::lazy-update || fail

  # install cifs-utils
  apt::install cifs-utils || fail

  # shellrcd
  shellrcd::install || fail

  # install nodejs
  apt::install-nodejs || fail

  # install bitwarden
  bitwarden::install-cli || fail

  # the following commands use bitwarden, that requires password entry
  # subshell for unlocked bitwarden
  (
    # mount host folder
    ubuntu-workstation::setup-my-folder-mount || fail
  ) || fail
}
