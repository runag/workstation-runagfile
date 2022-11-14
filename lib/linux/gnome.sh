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

workstation::linux::gnome::configure() {
  #
  # use dconf-editor to find key/value pairs
  #
  # Please do not use dbus-launch here because it will introduce side-effect to "git:add-credentials-to-gnome-keyring"
  # and to "ssh::add-key-password-to-gnome-keyring"
  #

  # Terminal
  gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ copy '<Primary>c'
  gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ paste '<Primary>v'
  gsettings set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false || fail

  local profile_id; if profile_id="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null)"; then
    local profile_path="Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id:1:-1}/"

    gsettings set org.gnome."${profile_path}" exit-action 'hold' || fail
  fi

  # Dash
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false || fail
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM' || fail
  gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false || fail
  gsettings set org.gnome.shell.extensions.dash-to-dock show-delay 0.01 || fail
  gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false || fail
  gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false || fail

  if vmware::is_inside_vm; then
    gsettings set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false || fail
    gsettings set org.gnome.mutter edge-tiling false || fail # maybe I should turn it on sometime later, check if it works well in a virtual machine
  else
    gsettings set org.gnome.desktop.interface enable-hot-corners true || fail
  fi

  # Nautilus
  gsettings set org.gnome.nautilus.list-view use-tree-view true || fail
  gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' || fail
  gsettings set org.gnome.nautilus.preferences show-delete-permanently true || fail

  # Automatic timezone
  gsettings set org.gnome.desktop.datetime automatic-timezone true || fail

  # Disable sound alerts
  gsettings set org.gnome.desktop.sound event-sounds false || fail

  # Mouse, 3200 dpi
  gsettings set org.gnome.desktop.peripherals.mouse speed -0.9 || fail

  # Theme
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || fail

  # Disable screen lock
  gsettings set org.gnome.desktop.session idle-delay 0 || fail
}
