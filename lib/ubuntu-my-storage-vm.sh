#!/usr/bin/env bash

#  Copyright 2012-2019 Stanislav Senotrusov <stan@senotrusov.com>
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

my-storage-vm::deploy() {
  # hostname
  ubuntu::set-hostname "stan-storage" || fail

  # update and upgrade
  apt::update || fail
  apt::dist-upgrade || fail

  # basic tools, contains curl so it have to be first
  ubuntu::packages::install-basic-tools || fail

  # shellrcd
  shellrcd::install || fail
  shellrcd::use-nano-editor || fail
  shellrcd::sopka-lib-path || fail

  # open-vm-tools
  if ubuntu::vmware::is-inside-vm; then
    apt::install open-vm-tools || fail
  fi

  # avahi daemon
  apt::install avahi-daemon || fail

  # cifs
  apt::install cifs-utils || fail

  # rclone
  ubuntu::install-rclone || fail

  # borg
  apt::install borgbackup || fail

  # ssh-import-id
  apt::install ssh-import-id || fail

  # cleanup
  apt::autoremove || fail

  # bitwarden and bitwarden cli
  sudo snap install bw || fail

  # import ssh key
  ssh-import-id gh:senotrusov || fail

  # configure git
  git::configure || fail

  # enable-linger
  sudo loginctl enable-linger "${USER}" || fail

  # backup configuration
  (
    ssh::install-keys "my borg storage ssh private key" "my borg storage ssh public key" || fail
    fs::mount-cifs "//STAN-LAPTOP/users/stan/Documents" "stan-documents" "my microsoft account" || fail
    borg::configure-backup-credentials "stan-documents" || fail
  ) || fail

  touch "${HOME}/.sopka.my-storage-vm.deployed" || fail

  if [ -t 1 ]; then
    ubuntu::display-if-restart-required || fail
    tools::display-elapsed-time || fail
  fi
}

backup::stan-documents() {
  . "${HOME}/.stan-documents.backup-credentials" || fail
  "$@" || fail
}

backup::stan-documents::create() (
  . "${HOME}/.stan-documents.backup-credentials" || fail

  # The purpose of this is to see relative paths in backup
  cd "${HOME}/stan-documents" || fail

  # I should probably make a special user service to wait until the network is up and source directory is mounted
  findmnt -M . >/dev/null || fail "${mountPoint} is not mounted"
  ping -c 3 -n -q "${STORAGE_HOST}" >/dev/null 2>&1 || fail "${STORAGE_HOST} is not reachable"

  local progressMaybe=""; test -t 1 && progressMaybe="--progress"

  borg create $progressMaybe --stats --files-cache=ctime,size --compression zstd "::{utcnow}" distfiles educational-media notes || fail

  tools::once-per-day backup::stan-documents::prune-and-check || fail
)

backup::stan-documents::prune-and-check() {
  borg prune --stats --keep-within 4d --keep-daily=7 --keep-weekly=4 --keep-monthly=24 || fail
  borg check --repository-only || fail
}
