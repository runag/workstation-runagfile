#!/usr/bin/env bash

#  Copyright 2012-2019 Stanislav Senotrusov <stan@senotrusov.com>
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

ubuntu::desktop::configure() {
  apt::install dconf-editor || fail

  # configure gnome desktop
  ubuntu::desktop::configure-gnome || fail

  # imwheel
  apt::install imwheel || fail
  ubuntu::desktop::setup-imwhell || fail

  # fixes for nvidia
  if nvidia::is-card-present; then
    nvidia::fix-screen-tearing || fail
    nvidia::fix-gpu-background-image-glitch || fail
  fi

  # enable wayland for firefox
  ubuntu::desktop::moz-enable-wayland || fail

  # remove user dirs
  ubuntu::desktop::remove-user-dirs || fail

  # hide folders
  ubuntu::desktop::hide-folder "Desktop" || fail
  ubuntu::desktop::hide-folder "snap" || fail
  ubuntu::desktop::hide-folder "VirtualBox VMs" || fail

  # vitals gnome shell extension
  if [ "${INSTALL_VITALS:-}" = true ]; then
    ubuntu::desktop::install-vitals || fail
  fi
}

ubuntu::desktop::remove-user-dirs() {
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

    fs::remove-dir-if-empty "$HOME/Documents" || fail
    fs::remove-dir-if-empty "$HOME/Music" || fail
    fs::remove-dir-if-empty "$HOME/Pictures" || fail
    fs::remove-dir-if-empty "$HOME/Public" || fail
    fs::remove-dir-if-empty "$HOME/Templates" || fail
    fs::remove-dir-if-empty "$HOME/Videos" || fail

    if [ -f "$HOME/examples.desktop" ]; then
      rm "$HOME/examples.desktop" || fail
    fi

    xdg-user-dirs-update || fail
  fi
}

# use dconf-editor to find key/value pairs
#
# Don't use dbus-launch here because it will introduce
# side-effect to git::ubuntu::add-credentials-to-keyring and ssh::ubuntu::add-key-password-to-keyring

ubuntu::desktop::configure-gnome() {
  if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    # Terminal
    if gsettings get org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled >/dev/null; then
      gsettings set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false || fail
    fi

    if gsettings get org.gnome.Terminal.ProfilesList default >/dev/null; then
      local terminalProfile; terminalProfile="$(gsettings get org.gnome.Terminal.ProfilesList default)" || fail "Unable to determine terminalProfile ($?)"
      local profilePath="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${terminalProfile:1:-1}/"

      gsettings set "$profilePath" exit-action 'hold' || fail
      gsettings set "$profilePath" login-shell true || fail
    fi

    # Nautilus
    if gsettings list-keys org.gnome.nautilus >/dev/null; then
      gsettings set org.gnome.nautilus.list-view default-zoom-level 'small' || fail
      gsettings set org.gnome.nautilus.list-view use-tree-view true || fail
      gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' || fail
      gsettings set org.gnome.nautilus.preferences show-delete-permanently true || fail
      gsettings set org.gnome.nautilus.preferences show-hidden-files true || fail
    fi

    # Desktop 18.04
    if gsettings list-keys org.gnome.nautilus.desktop >/dev/null; then
      gsettings set org.gnome.nautilus.desktop trash-icon-visible false || fail
      gsettings set org.gnome.nautilus.desktop volumes-visible false || fail
    fi

    # Desktop 19.10
    if gsettings list-keys org.gnome.shell.extensions.desktop-icons >/dev/null; then
      gsettings set org.gnome.shell.extensions.desktop-icons show-trash false || fail
      gsettings set org.gnome.shell.extensions.desktop-icons show-home false || fail
    fi

    # Auto set time zone
    if gsettings get org.gnome.desktop.datetime automatic-timezone >/dev/null; then
      gsettings set org.gnome.desktop.datetime automatic-timezone true || fail
    fi

    # Dash appearance
    if gsettings get org.gnome.shell.extensions.dash-to-dock dash-max-icon-size >/dev/null; then
      gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 38 || fail
    fi

    # Sound alerts
    if gsettings get org.gnome.desktop.sound event-sounds >/dev/null; then
      gsettings set org.gnome.desktop.sound event-sounds false || fail
    fi

    # 1600 DPI mouse
    if gsettings get org.gnome.desktop.peripherals.mouse speed >/dev/null; then
      gsettings set org.gnome.desktop.peripherals.mouse speed -0.75 || fail
    fi

    # Input sources
    # ('xkb', 'ru+mac')
    if gsettings get org.gnome.desktop.input-sources sources >/dev/null; then
      gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ru')]" || fail
    fi

    # Enable fractional scaling
    if gsettings get org.gnome.mutter experimental-features >/dev/null; then
      gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'x11-randr-fractional-scaling']" || fail
    fi
  fi
}

ubuntu::desktop::disable-screen-lock() {
  if gsettings get org.gnome.desktop.session idle-delay >/dev/null; then
    gsettings set org.gnome.desktop.session idle-delay 0 || fail
  fi
}
