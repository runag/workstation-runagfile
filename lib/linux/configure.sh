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
  ## System ##

  # enable systemd user instance without the need for the user to login
  sudo loginctl enable-linger "${USER}" || fail

  # configure bash
  shellrc::install_append_to_bash_history_file_after_each_command_rc || fail

  # configure ssh
  ssh::add_ssh_config_d_include_directive || fail

  # increase inotify limits
  linux::configure_inotify || fail

  # udisks mount options
  workstation::linux::storage::configure_udisks_mount_options || fail

  # configuration related to the case when the system is running inside a virtual machine
  if vmware::is_inside_vm; then
    # to save myself some time on btrfs configuration
    fstab::add_mount_option btrfs flushoncommit || fail
    fstab::add_mount_option btrfs noatime || fail

    # for network to work
    vmware::install_vm_network_loss_workaround || fail

    # for backup to work
    vmware::configure_passwordless_sudo_for_dmidecode_in_get_machine_uuid || fail

    # disable unattended-upgrades, not so sure about that
    # apt::remove unattended-upgrades || fail
  fi


  ## Developer ##

  # configure git
  workstation::configure_git || fail

  # set editor
  shellrc::install_editor_rc micro || fail

  # install vscode configuration
  workstation::vscode::install_extensions || fail
  workstation::vscode::install_config || fail

  # install sublime merge configuration
  workstation::sublime_merge::install_config || fail

  # install sublime text configuration
  workstation::sublime_text::install_config || fail

  # postgresql
  sudo systemctl --quiet --now enable postgresql || fail
  postgresql::create_role_if_not_exists "${USER}" WITH SUPERUSER CREATEDB CREATEROLE LOGIN || fail


  ## Desktop ##

  # hide some directories
  workstation::linux::hide-file "Desktop" || fail
  workstation::linux::hide-file "Documents" || fail
  workstation::linux::hide-file "Music" || fail
  workstation::linux::hide-file "Public" || fail
  workstation::linux::hide-file "Templates" || fail
  workstation::linux::hide-file "Videos" || fail
  workstation::linux::hide-file "snap" || fail

  # configure gnome desktop
  workstation::linux::gnome::configure || fail

  # configure and start imwheel. When running ubuntu guest in vmware workstation, mouse scrolling stops if you scroll
  # and move your mouse at the same time. Imwheel somehow fixes that.
  workstation::linux::imwheel::deploy || fail
}

workstation::linux::hide-file() {
  ( umask 0177 && touch "${HOME}/.hidden" ) || fail
  file::append_line_unless_present "$1" "${HOME}/.hidden" || fail
}
