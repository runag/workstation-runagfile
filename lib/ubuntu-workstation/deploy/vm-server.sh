#!/usr/bin/env bash

#  Copyright 2012-2022 Stanislav Senotrusov <stan@senotrusov.com>
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

ubuntu_workstation::deploy_vm_server() {
  # remove unattended-upgrades
  apt::remove unattended-upgrades || fail

  # perform autoremove, update and upgrade
  apt::autoremove_lazy_update_and_maybe_dist_upgrade || fail

  # install open-vm-tools
  if vmware::is_inside_vm; then
    apt::install open-vm-tools || fail
  fi

  # install and configure sshd
  sshd::disable_password_authentication || fail
  apt::install openssh-server || fail
  sudo systemctl --quiet --now enable ssh || fail
  sudo systemctl reload ssh || fail

  # import ssh key
  apt::install ssh-import-id || fail
  ssh-import-id gh:senotrusov || fail

  # install avahi daemon
  apt::install avahi-daemon || fail

  log::success "Done ubuntu_workstation::deploy_vm_server" || fail
}
