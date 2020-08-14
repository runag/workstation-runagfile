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

ubuntu::deploy-my-storage-vm() {
  # update and upgrade
  apt::update || fail
  apt::dist-upgrade || fail

  # hostname
  ubuntu::set-hostname "stan-storage" || fail

  # basic tools, contains curl so it have to be first
  ubuntu::packages::install-basic-tools || fail

  # bitwarden and bitwarden cli
  sudo snap install bw || fail

  # shellrcd
  shellrcd::install || fail
  shellrcd::use-nano-editor || fail
  shellrcd::sopka-lib-path || fail

  # open-vm-tools
  if ubuntu::vmware::is-inside-vm; then
    apt::install open-vm-tools || fail
    # ubuntu::vmware::add-hgfs-automount || fail
    # ubuntu::vmware::symlink-hgfs-mounts || fail
  fi

  # ssh public key
  apt::install ssh-import-id || fail
  ssh-import-id gh:senotrusov || fail

  # git
  git::configure || fail

  # avahi daemon
  apt::install avahi-daemon || fail

  # cifs
  apt::install cifs-utils || fail

  # rclone
  ubuntu::install-rclone || fail

  # borg
  apt::install borgbackup || fail

  # cleanup
  apt::autoremove || fail

  # storage configuration
  (
    bitwarden::unlock || fail
    my-storage-vm::configure-windows-share || fail
    my-storage-vm::configure-access-to-borg-storage || fail
  ) || fail

  if [ -t 1 ]; then
    ubuntu::display-if-restart-required || fail
    tools::display-elapsed-time || fail
  fi
}

my-storage-vm::configure-windows-share() {
  local mountPoint="${HOME}/windows-documents"
  local credentialsFile="${HOME}/.smbcredentials"
  local fstabTag="# windows-documents cifs share"
  local serverName="STAN-LAPTOP"
  local bwItem="my microsoft account"
  local cifsUsername
  local cifsPassword

  mkdir -p "${mountPoint}" || fail

  if ! grep --quiet --fixed-strings --line-regexp "${fstabTag}" /etc/fstab; then
    echo "${fstabTag}" | sudo tee --append /etc/fstab || fail
    echo "//${serverName}/users/stan/Documents ${mountPoint} cifs credentials=${credentialsFile},file_mode=0640,dir_mode=0750,uid=${USER},gid=${USER} 0 0" | sudo tee --append /etc/fstab || fail
  fi

  if [ ! -f "${credentialsFile}" ]; then
    bitwarden::unlock || fail
    cifsUsername="$(bw get username "${bwItem}")" || fail
    cifsPassword="$(bw get password "${bwItem}")" || fail
    builtin printf "username=${cifsUsername}\npassword=${cifsPassword}\n" | (umask 077 && tee "${credentialsFile}" >/dev/null) || fail
  fi

  sudo mount -a || fail
}

my-storage-vm::configure-access-to-borg-storage(){
  local bwBorgStorageItem="my borg storage"

  local borgStorageUsername
  local borgStorageUri
  local borgStorageHost
  local borgStoragePort

  borgStorageUsername="$(bw get username "${bwBorgStorageItem}")" || fail
  borgStorageUri="$(bw get uri "${bwBorgStorageItem}")" || fail

  borgStorageHost="$(echo "${borgStorageUri}" | cut -d ":" -f 1)" || fail
  borgStoragePort="$(echo "${borgStorageUri}" | cut -d ":" -f 2)" || fail

  ssh::install-keys "my borg storage ssh private key" "my borg storage ssh public key" || fail
  ssh::add-host-to-known-hosts "${borgStorageHost}" "${borgStoragePort}" || fail
}
