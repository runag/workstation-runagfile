#!/usr/bin/env bash

#  Copyright 2012-2021 Stanislav Senotrusov <stan@senotrusov.com>
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

ubuntu-workstation::configure-system() {
  # increase inotify limits
  linux::configure-inotify || fail

  # enable systemd user instance without the need for the user to login
  sudo loginctl enable-linger "${USER}" || fail
}

ubuntu-workstation::configure-git() {
  git::configure-user || fail
  git config --global core.autocrlf input || fail
}

ubuntu-workstation::configure-servers() {
  # postgresql
  sudo systemctl --now enable postgresql || fail
  postgresql::create-superuser-for-local-account || fail
}

ubuntu-workstation::configure-desktop-software() {
  if [ -n "${DISPLAY:-}" ]; then
    # configure firefox
    ubuntu-workstation::configure-firefox || fail
    firefox::enable-wayland || fail

    # install sublime configuration
    sublime::install-config || fail

    # configure imwheel
    ubuntu-workstation::configure-imwhell || fail

    # configure home folders
    ubuntu-workstation::configure-home-folders || fail

    # apply fixes for nvidia
    # TODO: Check if I really need those fixes nowadays
    # if nvidia::is-card-present; then
    #   nvidia::fix-screen-tearing || fail
    #   nvidia::fix-gpu-background-image-glitch || fail
    # fi

    # configure gnome desktop
    ubuntu-workstation::configure-gnome || fail
  fi
}

ubuntu-workstation::configure-firefox() {
  firefox::set-pref "mousewheel.default.delta_multiplier_x" 200 || fail
  firefox::set-pref "mousewheel.default.delta_multiplier_y" 200 || fail
}

ubuntu-workstation::configure-imwhell() {
  local repetitions="2"
  local outputFile="${HOME}/.imwheelrc"
  tee "${outputFile}" <<SHELL || fail "Unable to write file: ${outputFile} ($?)"
".*"
None,      Up,   Button4, ${repetitions}
None,      Down, Button5, ${repetitions}
Control_L, Up,   Control_L|Button4
Control_L, Down, Control_L|Button5
Shift_L,   Up,   Shift_L|Button4
Shift_L,   Down, Shift_L|Button5
SHELL

  if [ ! -d "${HOME}/.config/autostart" ]; then
    mkdir -p "${HOME}/.config/autostart" || fail
  fi

  local outputFile="${HOME}/.config/autostart/imwheel.desktop"
  tee "${outputFile}" <<SHELL || fail "Unable to write file: ${outputFile} ($?)"
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
SHELL

  /usr/bin/imwheel --kill
}

ubuntu-workstation::configure-home-folders() {
  local dirsFile="${HOME}/.config/user-dirs.dirs"

  if [ -f "${dirsFile}" ]; then
    local tmpFile; tmpFile="$(mktemp)" || fail

    if [ -d "$HOME/Desktop" ]; then
      echo 'XDG_DESKTOP_DIR="$HOME/Desktop"' >>"${tmpFile}" || fail
    fi

    if [ -d "$HOME/Downloads" ]; then
      echo 'XDG_DOWNLOADS_DIR="$HOME/Downloads"' >>"${tmpFile}" || fail
    fi

    mv "${tmpFile}" "${dirsFile}" || fail

    echo 'enabled=false' >"${HOME}/.config/user-dirs.conf" || fail

    dir::remove-if-empty \
      "$HOME/Documents" \
      "$HOME/Music" \
      "$HOME/Pictures" \
      "$HOME/Public" \
      "$HOME/Templates" \
      "$HOME/Videos" || fail

    if [ -f "$HOME/examples.desktop" ]; then
      rm "$HOME/examples.desktop" || fail
    fi

    xdg-user-dirs-update || fail
  fi

  file::append-line-unless-present "Desktop" "${HOME}/.hidden" || fail
  file::append-line-unless-present "snap" "${HOME}/.hidden" || fail
}

ubuntu-workstation::configure-gnome() {
  # use dconf-editor to find key/value pairs
  #
  # Do not use dbus-launch here because it will introduce
  # side-effect to git::add-credentials-to-gnome-keyring and ssh::add-key-password-to-gnome-keyring
  #
  (
    gnome-set() { gsettings set "org.gnome.$1" "${@:2}" || fail; }
    gnome-get() { gsettings get "org.gnome.$1" "${@:2}"; }

    # Terminal
    local profileId profilePath

    if profileId="$(gnome-get Terminal.ProfilesList default 2>/dev/null)"; then
      local profilePath="Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profileId:1:-1}/"
      
      gnome-set "${profilePath}" exit-action 'hold' || fail
      gnome-set "${profilePath}" login-shell true || fail
    fi

    gnome-set Terminal.Legacy.Settings menu-accelerator-enabled false || fail
    gnome-set Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ copy '<Primary>c'
    gnome-set Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ paste '<Primary>v'

    # Desktop
    gnome-set shell.extensions.desktop-icons show-trash false || fail
    gnome-set shell.extensions.desktop-icons show-home false || fail

    # Dash
    gnome-set shell.extensions.dash-to-dock dash-max-icon-size 32 || fail
    gnome-set shell.extensions.dash-to-dock dock-fixed false || fail
    gnome-set shell.extensions.dash-to-dock dock-position 'BOTTOM' || fail
    gnome-set shell.extensions.dash-to-dock hide-delay 0.10000000000000001 || fail
    gnome-set shell.extensions.dash-to-dock require-pressure-to-show false || fail
    gnome-set shell.extensions.dash-to-dock show-apps-at-top true || fail
    gnome-set shell.extensions.dash-to-dock show-delay 0.10000000000000001 || fail

    # Nautilus
    gnome-set nautilus.list-view default-zoom-level 'small' || fail
    gnome-set nautilus.list-view use-tree-view true || fail
    gnome-set nautilus.preferences default-folder-viewer 'list-view' || fail
    gnome-set nautilus.preferences show-delete-permanently true || fail
    gnome-set nautilus.preferences show-hidden-files true || fail

    # Automatic timezone
    gnome-set desktop.datetime automatic-timezone true || fail

    # Input sources
    # on mac host: ('xkb', 'ru+mac')
    gnome-set desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ru')]" || fail

    # Disable sound alerts
    gnome-set desktop.sound event-sounds false || fail

    # Enable fractional scaling
    # gnome-set mutter experimental-features "['scale-monitor-framebuffer', 'x11-randr-fractional-scaling']" || fail

    # 1600 DPI mouse
    gnome-set desktop.peripherals.mouse speed -0.75 || fail
  ) || fail
}

ubuntu-workstation::configure-host-folders-mount() {
  local hostIpAddress; hostIpAddress="$(vmware::get-host-ip-address)" || fail

  # bitwarden-object: "my microsoft account"
  mount::cifs "//${hostIpAddress}/my" "my" "my microsoft account" || fail
  mount::cifs "//${hostIpAddress}/ephemeral-data" "ephemeral-data" "my microsoft account" || fail
}

ubuntu-workstation::configure-tailscale() {
  local tailscaleKey

  bitwarden::unlock || fail

  # bitwarden-object: "my tailscale reusable key"
  tailscaleKey="$(NODENV_VERSION=system bw get password "my tailscale reusable key")" || fail

  sudo tailscale up \
    --authkey "${tailscaleKey}" \
    || fail
}
