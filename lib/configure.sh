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

workstation::linux::configure() (
  # Load operating system identification data
  . /etc/os-release || fail

  ## System ##

  # enable systemd user instance without the need for the user to login
  sudo loginctl enable-linger "${USER}" || fail

  # configure bash
  shellfile::install_flush_history_rc || fail
  shellfile::install_short_prompt_rc || fail
  shellfile::install_fzf_rc || fail

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

  # disable unattended-upgrades, not so sure about that
  # apt::remove unattended-upgrades || fail

  ## Developer ##

  # configure git
  workstation::configure_git || fail

  # set editor
  shellfile::install_editor_rc micro || fail
  workstation::micro::install_config || fail

  # install vscode configuration
  workstation::vscode::install_extensions || fail
  workstation::vscode::install_config || fail

  # install sublime merge configuration
  workstation::sublime_merge::install_config || fail

  # install sublime text configuration
  workstation::sublime_text::install_config || fail

  # postgresql
  # run initdb if needed
  if [ "${ID:-}" = arch ] && sudo test ! -d /var/lib/postgres/data; then
    postgresql::as_postgres_user initdb -D /var/lib/postgres/data || fail
  fi
  sudo systemctl --quiet --now enable postgresql || fail
  postgresql::create_role_if_not_exists --with "SUPERUSER CREATEDB CREATEROLE LOGIN" || fail

  ## Desktop ##

  # configure gnome desktop
  workstation::linux::gnome::configure || fail

  # configure and start imwheel, some software need faster scrolling on X11
  workstation::linux::imwheel::deploy || fail

  # firefox
  # TODO: remove as debian's firefox reaches version 121
  firefox::enable_wayland || fail
)

workstation::linux::gnome::configure() (
  # Load operating system identification data
  . /etc/os-release || fail
 
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

  local dash_to_dock_schema=()

  if [ "${ID:-}" = debian ] || [ "${ID:-}" = arch ]; then
    export PATH="${HOME}/.local/bin:${PATH}"

    # Install and upgrade gnome-extensions-cli
    pipx install --force gnome-extensions-cli || fail
    pipx upgrade gnome-extensions-cli || fail

    # Install Dash to Dock
    gnome-extensions-cli install dash-to-dock@micxgx.gmail.com || fail
    dash_to_dock_schema+=(--schemadir "${HOME}/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas/")

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

  # Dash-to-dock
  gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock animation-time 0.1 || fail
  gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock dock-fixed false || fail # "fixed" means it always visible
  gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT' || fail
  gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock extend-height false || fail
  gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock hide-delay 0.01 || fail
  gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock intellihide-mode 'ALL_WINDOWS' || fail
  gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock multi-monitor true || fail
  gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock pressure-threshold 15.0 || fail
  gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock running-indicator-dominant-color true || fail
  gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS' || fail
  gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock show-delay 0.01 || fail
  gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock show-mounts false || fail
  gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock show-trash false || fail

  if gsettings "${dash_to_dock_schema[@]}" range org.gnome.shell.extensions.dash-to-dock click-action | grep -qFx "'focus-or-appspread'"; then
    gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock click-action 'focus-or-appspread' || fail
  else
    gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock click-action 'focus-or-previews' || fail
  fi

  if gsettings "${dash_to_dock_schema[@]}" range org.gnome.shell.extensions.dash-to-dock scroll-action | grep -qFx "'switch-workspace'"; then
    gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock scroll-action 'switch-workspace' || fail
  else
    gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock scroll-switch-workspace true || fail
  fi

  if systemd-detect-virt --quiet; then
    # No pressure in VM
    gsettings "${dash_to_dock_schema[@]}" set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false || fail 
  fi

  # No hot corners in VM
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
  if [ "${ID:-}" = debian ] || [ "${ID:-}" = arch ]; then
    gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"

    gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"
  fi

  # Move to workspace keybindings
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Super>F1']" || fail
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Super>F2']" || fail
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Super>F3']" || fail
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Super>F4']" || fail
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Shift><Super>F5']" || fail
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<Shift><Super>F6']" || fail

  # Switch to workspace keybindings
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>F1']" || fail
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>F2']" || fail
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>F3']" || fail
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>F4']" || fail
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>F5']" || fail
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>F6']" || fail
)

# to debug:
#   /usr/bin/imwheel --kill --detach --debug
#
# to disable:
#   rm "${HOME}/.config/autostart/imwheel.desktop"
#   pkill --full "/usr/bin/imwheel"

workstation::linux::imwheel::deploy() {
  file::write --mode 0600 "${HOME}/.imwheelrc" <<EOF || fail
# In the absence of the following tedious list of modifiers,
# (alt/ctrl/shift/meta + scroll) does not work

"^(Sublime_merge|Sublime_text)$"
None,      Up,   Button4, 2
None,      Down, Button5, 2
Control_L, Up,   Control_L|Button4
Control_L, Down, Control_L|Button5
Control_R, Up,   Control_R|Button4
Control_R, Down, Control_R|Button5
Alt_L,     Up,   Button4, 4
Alt_L,     Down, Button5, 4
Alt_R,     Up,   Button4, 4
Alt_R,     Down, Button5, 4
Shift_L,   Up,   Shift_L|Button4
Shift_L,   Down, Shift_L|Button5
Shift_R,   Up,   Shift_R|Button4
Shift_R,   Down, Shift_R|Button5
Meta_L,    Up,   Meta_L|Button4
Meta_L,    Down, Meta_L|Button5
Meta_R,    Up,   Meta_R|Button4
Meta_R,    Down, Meta_R|Button5

# Without that wildcard match that seems just like a passthrough,
# well, it's not passing through without that

".*"
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
EOF

  dir::ensure_exists --user-only "${HOME}/.config/autostart" || fail

  file::write --mode 0600 "${HOME}/.config/autostart/imwheel.desktop" <<EOF || fail
[Desktop Entry]
Type=Application
Exec=/usr/bin/bash -c 'if [ "\${XDG_SESSION_TYPE:-}" = "x11" ]; then /usr/bin/imwheel; fi'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
OnlyShowIn=GNOME;XFCE;
Name[en_US]=IMWheel
Name=IMWheel
Comment[en_US]=Scripting for mouse wheel and buttons
Comment=Scripting for mouse wheel and buttons
EOF

  if [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then
    /usr/bin/imwheel --kill || fail
  fi
}

# Git
workstation::configure_git() {
  local user_media_path; user_media_path="$(linux::user_media_path)" || fail

  git config --global core.autocrlf input || fail
  git config --global init.defaultBranch main || fail
  git config --global url."${user_media_path}/workstation-sync/".insteadOf "/workstation-sync/" || fail
}

workstation::linux::storage::configure_udisks_mount_options() {
  file::write --sudo --mode 0644 /etc/udisks2/mount_options.conf <<SHELL || fail
[defaults]
btrfs_defaults=flushoncommit,noatime,compress=zstd
btrfs_allow=compress,compress-force,datacow,nodatacow,datasum,nodatasum,autodefrag,noautodefrag,degraded,device,discard,nodiscard,subvol,subvolid,space_cache,commit,flushoncommit,noatime
SHELL
}
