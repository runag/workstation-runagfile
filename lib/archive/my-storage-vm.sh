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

# if [ -f "${HOME}/.sopka.my-storage-vm.deployed" ] || tools::nothing-deployed; then
#   list+=(my-storage-vm::deploy)
# fi

# if [ -f "${HOME}/.stan-documents.backup-credentials" ]; then
#   list+=("backup::stan-documents borg::menu")
#   list+=("backup::stan-documents::create")
# fi

my-storage-vm::deploy() {
  # set hostname
  linux::set-hostname "stan-storage" || fail

  # perform apt update and upgrade
  apt::lazy-update-and-dist-upgrade || fail

  # install basic tools. curl is among them, so this line have to be on top of the script
  ubuntu::packages::install-basic-tools || fail

  # install shellrcd
  shellrcd::install || fail
  shellrcd::use-nano-editor || fail
  shellrcd::sopka-path || fail

  # install nodejs
  nodejs::ubuntu::install || fail

  # install bitwarden cli
  bitwarden::install-cli || fail

  # install open-vm-tools
  if vmware::is-inside-vm; then
    apt::install open-vm-tools || fail
  fi

  # install avahi daemon
  apt::install avahi-daemon || fail

  # install cifs-utils
  apt::install cifs-utils || fail

  # install rclone
  tools::install-rclone || fail

  # install borg
  apt::install borgbackup || fail

  # install ssh-import-id
  apt::install ssh-import-id || fail

  # perform cleanup
  apt::autoremove || fail

  # configure git
  git::configure || fail
  git::configure-user || fail

  # import ssh key
  ssh-import-id gh:senotrusov || fail

  # enable systemd user instance without the need for the user to login
  systemd::enable-linger || fail

  # configure backup
  # subshell for unlocked bitwarden
  (
    # bitwarden-object: "my borg storage ssh private key", "my borg storage ssh public key"
    ssh::install-keys "my borg storage" || fail

    # bitwarden-object: "my microsoft account"
    fs::mount-cifs "//192.168.131.1/users/stan/Documents" "stan-documents" "my microsoft account" || fail

    # bitwarden-object: "stan-documents backup storage", "stan-documents backup passphrase"
    borg::configure-backup-credentials "stan-documents" || fail

    borg::load-backup-credentials "stan-documents" || fail

    # install borg service, update timer only if it was manually enabled previously
    borg::systemd::init-service || fail
  ) || fail

  touch "${HOME}/.sopka.my-storage-vm.deployed" || fail

  # display footnotes if running on interactive terminal
  tools::perhaps-display-deploy-footnotes || fail
}

backup::stan-documents() {
  borg::load-backup-credentials "stan-documents" || fail
  "$@" || fail
}

backup::stan-documents::create() (
  borg::load-backup-credentials "stan-documents" || fail

  # The purpose of this is to have relative paths in backup
  cd "${HOME}/stan-documents" || fail

  # I should probably make a special user service to wait until the network is up and source directory is mounted
  findmnt -M . >/dev/null || fail
  ping -c 3 -n -q "${STORAGE_HOST}" >/dev/null 2>&1 || fail "${STORAGE_HOST} is not reachable"

  local progressMaybe=""; test -t 1 && progressMaybe="--progress"

  borg create $progressMaybe --stats --files-cache=ctime,size --compression zstd "::{utcnow}" distfiles educational-media notes || fail

  tools::once-per-day backup::stan-documents::prune-and-check || fail
)

backup::stan-documents::prune-and-check() {
  borg::load-backup-credentials "stan-documents" || fail

  borg prune --stats --keep-within 4d --keep-daily=14 --keep-weekly=8 --keep-monthly=24 || fail
  borg check --repository-only || fail
}
