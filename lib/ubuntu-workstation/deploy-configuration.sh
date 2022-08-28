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

ubuntu_workstation::deploy_configuration() {
  # configure git
  workstation::configure_git || fail

  # increase inotify limits
  linux::configure_inotify || fail

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

  # postgresql
  sudo systemctl --quiet --now enable postgresql || fail
  postgresql::create_role_if_not_exists "${USER}" WITH SUPERUSER CREATEDB CREATEROLE LOGIN || fail
}

ubuntu_workstation::deploy_opionated_configuration() {
  # set editor
  shellrc::install_editor_rc nano || fail

  # install vscode configuration
  workstation::vscode::install_extensions || fail
  workstation::vscode::install_config || fail

  # install sublime merge configuration
  workstation::sublime_merge::install_config || fail

  # install sublime text configuration
  workstation::sublime_text::install_config || fail

  # hide some folders
  ubuntu_workstation::hide-file "Desktop" || fail
  ubuntu_workstation::hide-file "Documents" || fail
  ubuntu_workstation::hide-file "Music" || fail
  ubuntu_workstation::hide-file "Public" || fail
  ubuntu_workstation::hide-file "Templates" || fail
  ubuntu_workstation::hide-file "Videos" || fail
  ubuntu_workstation::hide-file "snap" || fail

  # configure gnome desktop
  ubuntu_workstation::configure_gnome || fail

  # enable and configure imwheel
  # imwheel somehow fixes the bug when mouse scrolling stops working if you move the mouse at the same time
  # I observed it only when running ubuntu inside vmware workstation
  # ubuntu_workstation::configure_imwhell || fail
}

ubuntu_workstation::configure_gnome() {(
  # use dconf-editor to find key/value pairs
  #
  # Please do not use dbus-launch here because it will introduce side-effect to "git:add-credentials-to-gnome-keyring" and "ssh::add-key-password-to-gnome-keyring"
  #
  gnome_set() { gsettings set "org.gnome.$1" "${@:2}" || fail; }
  gnome_get() { gsettings get "org.gnome.$1" "${@:2}"; }

  # Terminal
  local profile_id profile_path

  if profile_id="$(gnome_get Terminal.ProfilesList default 2>/dev/null)"; then
    local profile_path="Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id:1:-1}/"
    
    gnome_set "${profile_path}" exit-action 'hold' || fail
    # TODO: I think I need to try to live with the default non-login shell
    # gnome_set "${profile_path}" login-shell true || fail
  fi

  gnome_set Terminal.Legacy.Settings menu-accelerator-enabled false || fail
  gnome_set Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ copy '<Primary>c'
  gnome_set Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ paste '<Primary>v'

  # Dash
  gnome_set shell.extensions.dash-to-dock dash-max-icon-size 32 || fail
  gnome_set shell.extensions.dash-to-dock dock-fixed false || fail
  gnome_set shell.extensions.dash-to-dock dock-position 'BOTTOM' || fail
  gnome_set shell.extensions.dash-to-dock hide-delay 0.10000000000000001 || fail
  gnome_set shell.extensions.dash-to-dock require-pressure-to-show false || fail
  gnome_set shell.extensions.dash-to-dock show-apps-at-top true || fail
  gnome_set shell.extensions.dash-to-dock show-delay 0.10000000000000001 || fail
  gnome_set shell.extensions.dash-to-dock show-mounts-only-mounted true || fail

  # Nautilus
  gnome_set nautilus.list-view default-zoom-level 'small' || fail
  gnome_set nautilus.list-view use-tree-view true || fail
  gnome_set nautilus.preferences default-folder-viewer 'list-view' || fail
  gnome_set nautilus.preferences show-delete-permanently true || fail

  # Automatic timezone
  gnome_set desktop.datetime automatic-timezone true || fail

  # Input sources
  # on mac host: ('xkb', 'ru+mac')
  gnome_set desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ru')]" || fail

  # Disable sound alerts
  gnome_set desktop.sound event-sounds false || fail

  # Mouse, 3200 dpi
  gnome_set desktop.peripherals.mouse speed -0.9 || fail

  # Theme
  gnome_set desktop.interface color-scheme 'prefer-dark' || fail
  gnome_set desktop.interface gtk-theme 'Yaru-dark' || fail

  # disable screen lock
  gnome_set desktop.session idle-delay 0 || fail
)}

ubuntu_workstation::configure_imwhell() {
  local repetitions="2"
 
  tee "${HOME}/.imwheelrc" <<EOF || fail
"^krita$"
None,      Up,   Button4
None,      Down, Button5
Control_L, Up,   Control_L|Button4
Control_L, Down, Control_L|Button5
Control_R, Up,   Control_R|Button4
Control_R, Down, Control_R|Button5
Alt_L,     Up,   Alt_L|Button4
Alt_L,     Down, Alt_L|Button5
Alt_R,     Up,   Alt_R|Button4
Alt_R,     Down, Alt_R|Button5
Shift_L,   Up,   Shift_L|Button4
Shift_L,   Down, Shift_L|Button5
Shift_R,   Up,   Shift_R|Button4
Shift_R,   Down, Shift_R|Button5
Meta_L,    Up,   Meta_L|Button4
Meta_L,    Down, Meta_L|Button5
Meta_R,    Up,   Meta_R|Button4
Meta_R,    Down, Meta_R|Button5

".*"
None,      Up,   Button4, ${repetitions}
None,      Down, Button5, ${repetitions}
Control_L, Up,   Control_L|Button4
Control_L, Down, Control_L|Button5
Control_R, Up,   Control_R|Button4
Control_R, Down, Control_R|Button5
Alt_L,     Up,   Alt_L|Button4
Alt_L,     Down, Alt_L|Button5
Alt_R,     Up,   Alt_R|Button4
Alt_R,     Down, Alt_R|Button5
Shift_L,   Up,   Shift_L|Button4
Shift_L,   Down, Shift_L|Button5
Shift_R,   Up,   Shift_R|Button4
Shift_R,   Down, Shift_R|Button5
Meta_L,    Up,   Meta_L|Button4
Meta_L,    Down, Meta_L|Button5
Meta_R,    Up,   Meta_R|Button4
Meta_R,    Down, Meta_R|Button5
EOF

  dir::make_if_not_exists "${HOME}/.config" 755 || fail
  dir::make_if_not_exists "${HOME}/.config/autostart" 700 || fail

  tee "${HOME}/.config/autostart/imwheel.desktop" <<EOF || fail
[Desktop Entry]
Type=Application
Exec=/usr/bin/imwheel
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
OnlyShowIn=GNOME;XFCE;
Name[en_US]=IMWheel
Name=IMWheel
Comment[en_US]=Custom scroll speed
Comment=Custom scroll speed
EOF

  /usr/bin/imwheel --kill
}
