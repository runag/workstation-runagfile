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

workstation::linux::gnome::configure() {(
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
