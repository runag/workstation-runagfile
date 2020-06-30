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

ubuntu::deploy-workstation() {
  ubuntu::install-packages || fail
  ubuntu::configure-workstation || fail
  ubuntu::display-if-restart-required || fail
  tools::display-elapsed-time || fail
}

ubuntu::install-packages() {
  # update and upgrade
  apt::update || fail
  apt::dist-upgrade || fail

  # basic tools, contains curl so it have to be first
  ubuntu::install-packages::basic-tools || fail

  # devtools
  ubuntu::install-packages::devtools || fail

  # git credential libsecret https://wiki.gnome.org/Projects/Libsecret
  apt::install gnome-keyring libsecret-tools libsecret-1-0 libsecret-1-dev || fail
  ubuntu::compile-git-credential-libsecret || fail

  # bitwarden cli
  sudo snap install bw || fail

  # ruby
  ruby::install-rbenv || fail

  # nodejs
  apt::add-yarn-source || fail
  apt::add-nodejs-source || fail
  apt::update || fail
  apt::install yarn nodejs || fail

  # vscode
  vscode::snap::install || fail

  # sublime merge & text
  sublime::apt::add-sublime-source || fail
  apt::update || fail
  sublime::apt::install-sublime-merge || fail
  sublime::apt::install-sublime-text || fail

  # meld (it will pull a whole gnome desktop as a dependency)
  apt::install meld || fail

  # chromium
  sudo snap install chromium || fail

  ## open-vm-tools
  apt::perhaps-install-open-vm-tools-desktop || fail

  # imwheel
  apt::install imwheel || fail

  # gnome configuration
  apt::install dconf-cli dconf-editor libglib2.0-bin || fail

  # corecoding-vitals-gnome-shell-extension
  apt::install gir1.2-gtop-2.0 lm-sensors || fail
  ubuntu::install-corecoding-vitals-gnome-shell-extension || fail

  # software for bare metal workstation
  if ubuntu::is-bare-metal; then
    apt::add-syncthing-source || fail
    apt::add-obs-studio-source || fail

    apt::update || fail

    apt::install syncthing || fail
    apt::install obs-studio guvcview || fail

    sudo snap install bitwarden || fail
    sudo snap install discord || fail
    sudo snap install skype --classic || fail
    sudo snap install telegram-desktop || fail

    if ! command -v libreoffice >/dev/null; then
      sudo snap install libreoffice || fail
    fi
  fi

  # Cleanup
  apt::autoremove || fail

  # sudo gem install rake solargraph || fail "Unable to install gems"
  # sudo gem update --system || fail "Unable to execute gem update --system"
  # sudo gem update || fail "Unable to update gems"
}

ubuntu::install-packages::basic-tools() {
  apt::install \
    curl \
    git \
    jq \
    mc ranger ncdu \
    htop \
    p7zip-full \
    tmux \
    sysbench \
    direnv \
    debian-goodies \
      || fail
}

ubuntu::install-packages::devtools() {
  apt::install \
    build-essential autoconf bison libncurses-dev libffi-dev libgdbm-dev libreadline-dev libssl-dev zlib1g-dev libyaml-dev libxml2-dev libxslt-dev \
    postgresql libpq-dev postgresql-contrib \
    sqlite3 libsqlite3-dev \
    redis-server \
    memcached \
    ruby-full \
    python3-pip python3-psycopg2 \
    ffmpeg imagemagick ghostscript libgs-dev \
    graphviz \
    shellcheck \
    apache2-utils \
    inotify-tools \
    awscli \
      || fail
}

ubuntu::configure-workstation() {
  # shellrcd
  shellrcd::install || fail
  shellrcd::use-nano-editor || fail
  shellrcd::sopka-src-path || fail
  shellrcd::hook-direnv || fail

  # ruby
  ruby::install-gemrc || fail
  shellrcd::rbenv || fail
  rbenv rehash || fail

  # nodejs

  # vscode
  vscode::install-config || fail
  vscode::install-extensions || fail

  # sublime text
  sublime::install-config || fail

  # increase inotify limits
  ubuntu::set-inotify-max-user-watches || fail

  # configure desktop
  ubuntu::configure-desktop || fail

  # IMWhell
  ubuntu::setup-imwhell || fail

  # NVIDIA fixes
  if ubuntu::is-nvidia-card-installed; then
    ubuntu::fix-nvidia-screen-tearing || fail
    ubuntu::fix-nvidia-gpu-background-image-glitch || fail
  fi

  # enable wayland for firefox
  ubuntu::moz-enable-wayland || fail

  # remove user dirs
  ubuntu::remove-user-dirs || fail

  # hide folders
  ubuntu::hide-folder "Desktop" || fail
  ubuntu::hide-folder "snap" || fail
  ubuntu::hide-folder "VirtualBox VMs" || fail

  # hgfs mounts
  if ubuntu::is-in-vmware-vm; then
    ubuntu::add-hgfs-automount || fail
    ubuntu::symlink-hgfs-mounts || fail
  fi

  # enable syncthing
  if ubuntu::is-bare-metal; then
    sudo systemctl enable --now "syncthing@${SUDO_USER}.service" || fail
  fi

  # SSH keys
  ssh::install-keys || fail
  ubuntu::add-ssh-key-password-to-keyring || fail

  # git
  git::configure || fail
  ubuntu::add-git-credentials-to-keyring || fail
}

ubuntu::remove-user-dirs() {
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

ubuntu::configure-desktop() {
  # use dconf-editor to find key/value pairs
  # Don't use dbus-launch here because it will introduce side-effect to
  # ubuntu::add-git-credentials-to-keyring and ubuntu::add-ssh-key-password-to-keyring

  if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    # Terminal
    if gsettings get org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled; then
      gsettings set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false || fail
    fi

    if gsettings get org.gnome.Terminal.ProfilesList default; then
      local terminalProfile; terminalProfile="$(gsettings get org.gnome.Terminal.ProfilesList default)" || fail "Unable to determine terminalProfile ($?)"
      local profilePath="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${terminalProfile:1:-1}/"

      gsettings set "$profilePath" exit-action 'hold' || fail
      gsettings set "$profilePath" login-shell true || fail
    fi

    # Nautilus
    if gsettings list-keys org.gnome.nautilus; then
      gsettings set org.gnome.nautilus.list-view default-zoom-level 'small' || fail
      gsettings set org.gnome.nautilus.list-view use-tree-view true || fail
      gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' || fail
      gsettings set org.gnome.nautilus.preferences show-delete-permanently true || fail
      gsettings set org.gnome.nautilus.preferences show-hidden-files true || fail
    fi

    # Desktop 18.04
    if gsettings list-keys org.gnome.nautilus.desktop; then
      gsettings set org.gnome.nautilus.desktop trash-icon-visible false || fail
      gsettings set org.gnome.nautilus.desktop volumes-visible false || fail
    fi

    # Desktop 19.10
    if gsettings list-keys org.gnome.shell.extensions.desktop-icons; then
      gsettings set org.gnome.shell.extensions.desktop-icons show-trash false || fail
      gsettings set org.gnome.shell.extensions.desktop-icons show-home false || fail
    fi

    # Disable screen lock
    if gsettings get org.gnome.desktop.session idle-delay; then
      gsettings set org.gnome.desktop.session idle-delay 0 || fail
    fi

    # Auto set time zone
    if gsettings get org.gnome.desktop.datetime automatic-timezone; then
      gsettings set org.gnome.desktop.datetime automatic-timezone true || fail
    fi

    # Dash appearance
    if gsettings get org.gnome.shell.extensions.dash-to-dock dash-max-icon-size; then
      gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 38 || fail
    fi

    # Sound alerts
    if gsettings get org.gnome.desktop.sound event-sounds; then
      gsettings set org.gnome.desktop.sound event-sounds false || fail
    fi

    # 1600 DPI mouse
    if gsettings get org.gnome.desktop.peripherals.mouse speed; then
      gsettings set org.gnome.desktop.peripherals.mouse speed -0.75 || fail
    fi

    # Input sources
    # ('xkb', 'ru+mac')
    if gsettings get org.gnome.desktop.input-sources sources; then
      gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ru')]" || fail
    fi

    # Enable fractional scaling
    if gsettings get org.gnome.mutter experimental-features; then
      gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'x11-randr-fractional-scaling']" || fail
    fi
  fi
}
