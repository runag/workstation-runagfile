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

  # Install extensions
  # 
  # To get full extension names use:
  #   gnome-extensions-cli list
  #
  local dash_to_dock_schemadir

  if [ "${ID:-}" = debian ]; then
    export PATH="${HOME}/.local/bin:${PATH}"

    # Install and upgrade gnome-extensions-cli
    pipx install --force gnome-extensions-cli || fail
    pipx upgrade gnome-extensions-cli || fail

    # Install Dash to Dock
    gnome-extensions-cli install dash-to-dock@micxgx.gmail.com || fail
    dash_to_dock_schemadir="${HOME}/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas/"
    # list keys
    # gsettings --schemadir "${dash_to_dock_schemadir}" list-recursively org.gnome.shell.extensions.dash-to-dock

    # Update extensions 
    gnome-extensions-cli update || fail
  fi

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
  # those are standalone extension defaults but not in ubuntu-packaged
  gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock dock-fixed false || fail # "fixed" means it always visible
  gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock extend-height false || fail

  # those are both for standalone extension and for ubuntu-packaged
  gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT' || fail
  gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock show-mounts false || fail
  gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock show-trash false || fail

  # At least in gnome 43 this setting is user-configurable from multitasking pane of control panel (org.gnome.shell.app-switcher current-workspace-only)
  # gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock isolate-workspaces true || fail

  # those are for standalone extension, I need to check if that is applicable to ubuntu-packaged

  if gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} range org.gnome.shell.extensions.dash-to-dock click-action | grep -qFx "'focus-or-appspread'"; then
    gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock click-action 'focus-or-appspread' || fail
  else
    gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock click-action 'focus-or-previews' || fail
  fi

  gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock multi-monitor true || fail
  gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock running-indicator-dominant-color true || fail
  gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS' || fail
  gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock scroll-switch-workspace true || fail

  # Hide mode
  gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock intellihide-mode 'ALL_WINDOWS' || fail

  # VM window usually have no edges
  if systemd-detect-virt --quiet; then
    gsettings ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false || fail 
  fi

  # show/hide
  gsettings set ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} org.gnome.shell.extensions.dash-to-dock show-delay 0.01 || fail
  gsettings set ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} org.gnome.shell.extensions.dash-to-dock hide-delay 0.01 || fail
  gsettings set ${dash_to_dock_schemadir:+--schemadir "${dash_to_dock_schemadir}"} org.gnome.shell.extensions.dash-to-dock pressure-threshold 15.0 || fail


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

  # Keybindings
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "\
    ['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', \
     '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', \
     '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']" || fail

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Pause' || fail
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'systemctl suspend' || fail
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Suspend' || fail

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>F12' || fail
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command "gsettings ${dash_to_dock_schemadir:+--schemadir $(printf "%q" "${dash_to_dock_schemadir}")} set org.gnome.shell.extensions.dash-to-dock dock-fixed true" || fail
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'show dock' || fail

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Super>F11' || fail
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command "gsettings ${dash_to_dock_schemadir:+--schemadir $(printf "%q" "${dash_to_dock_schemadir}")} set org.gnome.shell.extensions.dash-to-dock dock-fixed false" || fail
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'hide dock' || fail

  # Move to workspace keybindings
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Super>F1']" || fail
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Super>F2']" || fail
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Super>F3']" || fail
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Super>F4']" || fail
  # gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Shift><Super>F5']" || fail
  # gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<Shift><Super>F6']" || fail
  # gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "['<Shift><Super>F7']" || fail
  # gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "['<Shift><Super>F8']" || fail

  # Switch to workspace keybindings
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>F1']" || fail
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>F2']" || fail
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>F3']" || fail
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>F4']" || fail
  # gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>F5']" || fail
  # gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>F6']" || fail
  # gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "['<Super>F7']" || fail
  # gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "['<Super>F8']" || fail

  # Static workspaces
  # gsettings set org.gnome.mutter dynamic-workspaces false || fail
  # gsettings set org.gnome.desktop.wm.preferences num-workspaces 3 || fail
  # gsettings set org.gnome.desktop.wm.preferences workspace-names "['A (F1)', 'B (F2)', 'C (F3)', 'D (F4)']" || fail
)
