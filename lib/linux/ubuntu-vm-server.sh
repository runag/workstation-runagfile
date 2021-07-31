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

ubuntu-vm-server::deploy-base() {
  # perform cleanup
  apt::autoremove || fail

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
}

ubuntu-vm-server::install-shellrc() {
  shell::install-shellrc-directory-loader "${HOME}/.bashrc" || fail
  shell::install-sopka-path-shellrc || fail
  shell::install-nano-editor-shellrc || fail
}
