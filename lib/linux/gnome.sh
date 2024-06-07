#!/usr/bin/env bash

#  Copyright 2012-2024 Rùnag project contributors
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
  # use "dconf dump / >dump" to dump all records
  # to find the location of some setting of your particular interest you could make a full dump, change settings in GUI,
  # then make a second dump and compare it to the first one
  #
  # Please do not use dbus-launch here because it will introduce side-effect to "git:add-credentials-to-gnome-keyring"
  # and to "ssh::add-key-password-to-gnome-keyring"
  #

  # Terminal
  # gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ copy '<Primary>c'
  # gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ paste '<Primary>v'
  gsettings set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false || fail

  local profile_id; if profile_id="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null)"; then
    local profile_path="Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id:1:-1}/"

    gsettings set org.gnome."${profile_path}" exit-action 'hold' || fail
    gsettings set org.gnome."${profile_path}" bold-is-bright true || fail

    # sadly I can't select the color palette here as they are hardcoded in terminal app
  fi

  # Dash
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false || fail # "fixed" means it always visible
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT' || fail
  gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false || fail
  gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false || fail
  gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false || fail

  if workstation::vmware::is_inside_vm; then
    gsettings set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false || fail 
    gsettings set org.gnome.mutter edge-tiling false || fail
  else
    gsettings set org.gnome.desktop.interface enable-hot-corners true || fail
    gsettings set org.gnome.shell.extensions.dash-to-dock hide-delay 0.01 || fail
    gsettings set org.gnome.shell.extensions.dash-to-dock pressure-threshold 15.0 || fail
    gsettings set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show true || fail
    gsettings set org.gnome.shell.extensions.dash-to-dock show-delay 0.01 || fail
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
  gsettings set org.gnome.desktop.peripherals.mouse speed -1.0 || fail

  # Theme
  # gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || fail

  # Disable external search providers
  gsettings set org.gnome.desktop.search-providers disable-external true || fail

  # Disable screen lock
  gsettings set org.gnome.desktop.session idle-delay 0 || fail
}

workstation::linux::gnome::add_sound_control_launcher() {
  # Registered Categories https://specifications.freedesktop.org/menu-spec/latest/apa.html
  # Additional Categories https://specifications.freedesktop.org/menu-spec/latest/apas02.html

  local icons=(/snap/gnome-*/current/usr/share/icons/Adwaita/32x32/apps/multimedia-volume-control-symbolic.symbolic.png)
  local icon_path="${icons[-1]}"

  if [ -f "${icon_path}" ]; then
    local icon_line="Icon=${icon_path}"
  else
    local icon_line=""
  fi

  dir::should_exists --mode 0700 "${HOME}/.local" || fail
  dir::should_exists --mode 0700 "${HOME}/.local/share" || fail
  dir::should_exists --mode 0700 "${HOME}/.local/share/applications" || fail

  file::write "${HOME}/.local/share/applications/sound-control.desktop" <<SHELL || fail
[Desktop Entry]
Type=Application
Terminal=false
Name=Sound control
Exec=/usr/bin/gnome-control-center sound
Categories=AudioVideo;Audio;Settings;HardwareSettings;Music;
${icon_line}
SHELL

  sudo update-desktop-database || fail
}
