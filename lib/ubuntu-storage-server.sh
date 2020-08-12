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

ubuntu::deploy-storage-server() {
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
    ubuntu::vmware::add-hgfs-automount || fail
    ubuntu::vmware::symlink-hgfs-mounts || fail
  fi

  # avahi daemon
  apt::install avahi-daemon || fail

  # cleanup
  apt::autoremove || fail

  if [ -t 1 ]; then
    ubuntu::display-if-restart-required || fail
    tools::display-elapsed-time || fail
  fi
}
