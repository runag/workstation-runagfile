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

workstation::linux::gnome::configure() (
  # Load operating system identification data
  . /etc/os-release || softfail || return $?
 
  # use dconf-editor to find key/value pairs
  #
  # use "dconf dump / >dump" to dump all records
  # to find the location of some setting of your particular interest you could make a full dump, change settings in GUI,
  # then make a second dump and compare it to the first one
  #
  # Please do not use dbus-launch here because it will introduce side-effect to "git:add-credentials-to-gnome-keyring"
  # and to "ssh::add-key-password-to-gnome-keyring"

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

  # dash to dock
  local dash_to_dock_schema_args_maybe=()
  if ! gsettings list-keys org.gnome.shell.extensions.dash-to-dock >/dev/null 2>&1; then
    local dash_to_dock_schema_path="${HOME}/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas/"
    if [ -d "${dash_to_dock_schema_path}" ]; then
      dash_to_dock_schema_args_maybe+=(--schemadir "${dash_to_dock_schema_path}")
    fi
  fi

  # list keys
  # gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas/" list-recursively org.gnome.shell.extensions.dash-to-dock

  # Dash
  # those are standalone extension defaults but not in ubuntu-packaged
  gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock dock-fixed false || fail # "fixed" means it always visible
  gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock extend-height false || fail

  # those are both for standalone extension and for ubuntu-packaged
  gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT' || fail
  gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock show-mounts false || fail
  gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock show-trash false || fail

  # At least in gnome 43 this setting is user-configurable from multitasking pane of control panel (org.gnome.shell.app-switcher current-workspace-only)
  # gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock isolate-workspaces true || fail

  # those are for standalone extension, I need to check if that is applicable to ubuntu-packaged

  if gsettings "${dash_to_dock_schema_args_maybe[@]}" range org.gnome.shell.extensions.dash-to-dock click-action | grep -qFx "'focus-or-appspread'"; then
    gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock click-action 'focus-or-appspread' || fail
  else
    gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock click-action 'focus-or-previews' || fail
  fi

  gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock multi-monitor true || fail
  gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock running-indicator-dominant-color true || fail
  gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS' || fail
  gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock scroll-switch-workspace true || fail

  # Hide mode
  gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock intellihide-mode 'ALL_WINDOWS' || fail

  # VM window usually have no edges
  if systemd-detect-virt --quiet; then
    gsettings "${dash_to_dock_schema_args_maybe[@]}" set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false || fail 
  fi

  # not sure if that's a good idea anymore
  # gsettings set "${dash_to_dock_schema_args_maybe[@]}" org.gnome.shell.extensions.dash-to-dock hide-delay 0.01 || fail
  # gsettings set "${dash_to_dock_schema_args_maybe[@]}" org.gnome.shell.extensions.dash-to-dock pressure-threshold 15.0 || fail
  # gsettings set "${dash_to_dock_schema_args_maybe[@]}" org.gnome.shell.extensions.dash-to-dock show-delay 0.01 || fail


  # VM window usually have no edges
  if systemd-detect-virt --quiet; then
    gsettings set org.gnome.mutter edge-tiling false || fail
  else
    gsettings set org.gnome.desktop.interface enable-hot-corners true || fail
  fi

  # Workspaces
  gsettings set org.gnome.mutter workspaces-only-on-primary false || fail
  gsettings set org.gnome.shell.app-switcher current-workspace-only true || fail

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

  # Window title
  gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' || fail

  # Attach modal dialogs
  gsettings set org.gnome.mutter attach-modal-dialogs true || fail

  # Use Alt+Tab to switch windows on debian
  if [ "${ID:-}" = debian ]; then
    gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"

    gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"
  fi

  # Shortcuts
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Pause' || fail
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'systemctl suspend' || fail
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Suspend' || fail

  # TODO: dash_to_dock_schema_args_maybe maybe?
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>F12' || fail
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true' || fail
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'show dock' || fail

  # TODO: dash_to_dock_schema_args_maybe maybe?
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Super>F11' || fail
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false' || fail
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'hide dock' || fail
)

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
