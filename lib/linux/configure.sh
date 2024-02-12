#!/usr/bin/env bash

#  Copyright 2012-2022 Rùnag project contributors
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
  shell::set_flush_history_rc || fail

  # configure ssh
  ssh::add_ssh_config_d_include_directive || fail
  <<<"ServerAliveInterval 30" file::write --mode 0600 "${HOME}/.ssh/ssh_config.d/server-alive-interval.conf" || fail
  <<<"IdentitiesOnly yes" file::write --mode 0600 "${HOME}/.ssh/ssh_config.d/identities-only.conf" || fail

  # increase inotify limits
  linux::configure_inotify || fail

  # udisks mount options
  workstation::linux::storage::configure_udisks_mount_options || fail

  # btrfs configuration
  if [ "${CI:-}" != "true" ]; then
    fstab::add_mount_option --filesystem-type btrfs flushoncommit || fail
    fstab::add_mount_option --filesystem-type btrfs noatime || fail
  fi

  # configuration related to the case when the system is running inside a virtual machine
  if vmware::is_inside_vm; then
    # for network to work
    vmware::install_vm_network_loss_workaround || fail

    # for backup to work
    vmware::configure_passwordless_sudo_for_dmidecode_in_get_machine_uuid || fail
  fi

  # disable unattended-upgrades, not so sure about that
  # apt::remove unattended-upgrades || fail


  ## Developer ##

  # configure git
  workstation::configure_git || fail

  # set editor
  shell::set_editor_rc micro || fail
  workstation::install_micro_config || fail

  # install vscode configuration
  workstation::vscode::install_extensions || fail
  workstation::vscode::install_config || fail

  # install sublime merge configuration
  workstation::sublime_merge::install_config || fail

  # install sublime text configuration
  # workstation::sublime_text::install_config || fail

  # postgresql
  sudo systemctl --quiet --now enable postgresql || fail
  postgresql::create_role_if_not_exists --with "SUPERUSER CREATEDB CREATEROLE LOGIN" || fail


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
  workstation::linux::gnome::add_sound_control_launcher || fail

  # configure and start imwheel
  # When running ubuntu guest in vmware workstation, if you scroll and move your mouse at the same
  # time, then mouse scrolling stops. The use of imwheel fixes that somehow.
  if vmware::is_inside_vm; then
    workstation::linux::imwheel::deploy || fail
  fi

  # firefox
  if [ "${XDG_SESSION_TYPE}" = "wayland" ]; then
    firefox::enable_wayland || fail
  fi
}

workstation::linux::hide-file() {
  file::append_line_unless_present --mode 0600 "${HOME}/.hidden" "$1" || fail
}
