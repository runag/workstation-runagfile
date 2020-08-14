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

  # storage configuration
  (
    my-storage-vm::stan-documents::mount || fail
    my-storage-vm::stan-documents::configure-backup-credentials || fail
  ) || fail

  touch "${HOME}/.sopka.my-storage-vm.deployed" || fail

  if [ -t 1 ]; then
    ubuntu::display-if-restart-required || fail
    tools::display-elapsed-time || fail
  fi
}

my-storage-vm::stan-documents::mount() {
  local mountPoint="${HOME}/stan-documents"
  local credentialsFile="${HOME}/stan-documents.cifs-credentials"
  local fstabTag="# stan-documents"
  local serverName="STAN-LAPTOP"
  local bwItem="my microsoft account"

  mkdir -p "${mountPoint}" || fail

  if ! grep --quiet --fixed-strings --line-regexp "${fstabTag}" /etc/fstab; then
    echo "${fstabTag}" | sudo tee --append /etc/fstab || fail
    echo "//${serverName}/users/stan/Documents ${mountPoint} cifs credentials=${credentialsFile},file_mode=0640,dir_mode=0750,uid=${USER},gid=${USER} 0 0" | sudo tee --append /etc/fstab || fail
  fi

  if [ ! -f "${credentialsFile}" ]; then
    bitwarden::unlock || fail
    local cifsUsername; cifsUsername="$(bw get username "${bwItem}")" || fail
    local cifsPassword; cifsPassword="$(bw get password "${bwItem}")" || fail
    builtin printf "username=${cifsUsername}\npassword=${cifsPassword}\n" | (umask 077 && tee "${credentialsFile}" >/dev/null) || fail
  fi

  sudo mount -a || fail

  findmnt -M "${mountPoint}" >/dev/null || fail "${mountPoint} is not mounted"
}

my-storage-vm::stan-documents::configure-backup-credentials() {
  local backupName="stan-documents"
  local credentialsFile="${HOME}/${backupName}.backup-credentials"
  local privateKeyName="my borg storage ssh private key"
  local publicKeyName="my borg storage ssh public key"
  local storageBwItem="${backupName} backup storage"
  local passphraseBwItem="${backupName} backup passphrase"
  local backupPath="borg-backups/${backupName}"

  if [ ! -f "${credentialsFile}" ]; then
    bitwarden::unlock || fail

    local storageUsername; storageUsername="$(bw get username "${storageBwItem}")" || fail
    local storageUri; storageUri="$(bw get uri "${storageBwItem}")" || fail
    local storageHost; storageHost="$(echo "${storageUri}" | cut -d ":" -f 1)" || fail
    local storagePort; storagePort="$(echo "${storageUri}" | cut -d ":" -f 2)" || fail
    local passphrase; passphrase="$(bw get password "${passphraseBwItem}")" || fail

    ssh::install-keys "${privateKeyName}" "${publicKeyName}" || fail
    ssh::add-host-to-known-hosts "${storageHost}" "${storagePort}" || fail

    builtin printf "export BACKUP_NAME=$(printf "%q" "${backupName}")\nexport STORAGE_USERNAME=$(printf "%q" "${storageUsername}")\nexport STORAGE_HOST=$(printf "%q" "${storageHost}")\nexport STORAGE_PORT=$(printf "%q" "${storagePort}")\nexport BORG_REPO=$(printf "%q" "ssh://${storageUsername}@${storageUri}/./${backupPath}")\nexport BORG_PASSPHRASE=$(printf "%q" "${passphrase}")\n" | (umask 077 && tee "${credentialsFile}" >/dev/null) || fail
  fi
}

my-storage-vm::stan-documents() {
  . "${HOME}/stan-documents.backup-credentials" || fail
  "$@" || fail
}

borg::init() {
  borg init --encryption keyfile-blake2 --make-parent-dirs || fail
  borg::export-keys || fail
}

borg::export-keys() {
  local exportPath; exportPath="${HOME}/${BACKUP_NAME}-$(date +"%Y%m%dT%H%M%SZ")" || fail

  borg key export "${BORG_REPO}" "${exportPath}.key" || fail
  borg key export --qr-html "${BORG_REPO}" "${exportPath}.key.html" || fail
}

borg::connect-sftp() {
  sftp -P "${STORAGE_PORT}" "${STORAGE_USERNAME}@${STORAGE_HOST}" || fail
}

my-storage-vm::stan-documents::perform-backup() (
  . "${HOME}/stan-documents.backup-credentials" || fail

  if [ -t 1 ]; then
    local CREATE_VISUAL_ARGS="--stats --progress"
    local PRUNE_VISUAL_ARGS="--stats --list"
  fi

  # The purpose of this cd is to use relative to ${FROM_PATH} paths in backup
  cd "${HOME}/stan-documents" || fail
  
  findmnt -M . >/dev/null || fail "${mountPoint} is not mounted"

  borg create ${CREATE_VISUAL_ARGS:-} --files-cache=ctime,size --compression zstd "::{utcnow}" distfiles educational-media notes || fail
  borg prune ${PRUNE_VISUAL_ARGS:-} --keep-within 4d --keep-daily=7 --keep-weekly=4 --keep-monthly=24 || fail
)

