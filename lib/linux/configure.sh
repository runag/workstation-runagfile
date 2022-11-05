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

workstation::linux::configure() {
  ## Developer ##

  # configure git
  workstation::configure_git || fail

  # configure ssh
  dir::make_if_not_exists_and_set_permissions "${HOME}/.ssh" 0700 || fail
  dir::make_if_not_exists_and_set_permissions "${HOME}/.ssh/ssh_config.d" 0700 || fail
  <<<"Include ~/.ssh/ssh_config.d/*.conf" file::update_block "${HOME}/.ssh/config" "include files from ssh_config.d" --mode 0600 || fail

  # set editor
  shellrc::install_editor_rc micro || fail

  # install vscode configuration
  workstation::vscode::install_extensions || fail
  workstation::vscode::install_config || fail

  # install sublime merge configuration
  workstation::sublime_merge::install_config || fail

  # install sublime text configuration
  workstation::sublime_text::install_config || fail

  # increase inotify limits
  linux::configure_inotify || fail

  # postgresql
  sudo systemctl --quiet --now enable postgresql || fail
  postgresql::create_role_if_not_exists "${USER}" WITH SUPERUSER CREATEDB CREATEROLE LOGIN || fail


  ## System ##

  # disable unattended-upgrades
  apt::remove unattended-upgrades || fail

  # configure btrfs
  if [ "${CI:-}" != "true" ]; then
    fstab::add_mount_option btrfs commit=15 || fail
    fstab::add_mount_option btrfs discard=async || fail
    fstab::add_mount_option btrfs flushoncommit || fail
    fstab::add_mount_option btrfs noatime || fail
  fi

  # install vm-network-loss-workaround
  if vmware::is_inside_vm; then
    vmware::install_vm_network_loss_workaround || fail
  fi


  ## Desktop ##

  # hide some folders
  workstation::linux::hide-file "Desktop" || fail
  workstation::linux::hide-file "Documents" || fail
  workstation::linux::hide-file "Music" || fail
  workstation::linux::hide-file "Public" || fail
  workstation::linux::hide-file "Templates" || fail
  workstation::linux::hide-file "Videos" || fail
  workstation::linux::hide-file "snap" || fail

  # configure gnome desktop
  workstation::linux::gnome::configure || fail

  # configure and start imwheel
  # NOTE: When running ubuntu guest in vmware workstation, mouse scrolling stops if you scroll and move your mouse
  # at the same time. Imwheel somehow fixes that.
  workstation::linux::imwheel::configure 2 || fail
  workstation::linux::imwheel::reenable || fail
}

workstation::linux::hide-file() {
  ( umask 0177 && touch "${HOME}/.hidden" ) || fail
  file::append_line_unless_present "$1" "${HOME}/.hidden" || fail
}
