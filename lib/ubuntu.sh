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

ubuntu::deploy-sway-workstation() {
  DEPLOY_SWAY=true ubuntu::deploy-workstation || fail
}

ubuntu::deploy-workstation() {
  sway::determine-conditional-install-flag || fail

  ubuntu::install-packages || fail

  ubuntu::configure-workstation || fail

  if [ -x /usr/lib/update-notifier/update-motd-reboot-required ]; then
    /usr/lib/update-notifier/update-motd-reboot-required >&2 || fail
  fi

  deploy-lib::display-elapsed-time || fail
}

ubuntu::install-packages() {
  # Update the system
  apt::update || fail
  apt::perhaps-install-mbpfan || fail
  apt::dist-upgrade || fail

  # Basic tools, contains curl so it have to be first
  ubuntu::apt::install-basic-tools || fail

  # Additional sources
  apt::add-yarn-source || fail
  apt::add-nodejs-source || fail
  sublime::apt::add-sublime-source || fail

  # Additional sources for bare metal workstation
  if ubuntu::is-bare-metal; then
    apt::add-syncthing-source || fail
    apt::add-obs-studio-source || fail
  fi

  # Update apt
  apt::update || fail

  # Command-line tools
  ubuntu::apt::install-ruby-and-devtools || fail
  apt::install yarn nodejs || fail
  apt::install hwloc || fail
  apt::install tor || fail
  sudo snap install bw || fail

  # Editors
  vscode::snap::install || fail
  sublime::apt::install-sublime-merge || fail
  sublime::apt::install-sublime-text || fail
  apt::install meld || fail # TODO: meld will pull a whole gnome desktop as a dependency. I hope one day I'll find a snap package without all that stuff.

  # Chromium
  sudo snap install chromium || fail

  # Extra stuff for bare metal workstation
  if ubuntu::is-bare-metal; then
    apt::install syncthing || fail

    sudo snap install bitwarden || fail
    sudo snap install discord || fail
    sudo snap install skype --classic || fail
    sudo snap install telegram-desktop || fail

    if ! command -v libreoffice >/dev/null; then
      sudo snap install libreoffice || fail
    fi

    apt::install ffmpeg || fail
    apt::install obs-studio guvcview || fail
  fi

  # Misc tools for workstation

  ## dconf
  apt::install-dconf || fail

  ## gsettings
  apt::install libglib2.0-bin || fail

  ## https://wiki.gnome.org/Projects/Libsecret
  apt::install gnome-keyring libsecret-tools libsecret-1-0 libsecret-1-dev || fail

  ## I no longer use dbus-launch because because it will introduce side-effect for ubuntu::add-git-credentials-to-keyring and ubuntu::add-ssh-key-password-to-keyring
  ## apt::install dbus-x11 || fail

  ## open-vm-tools
  apt::perhaps-install-open-vm-tools-desktop || fail

  ## for corecoding-vitals-gnome-shell-extension
  apt::install gir1.2-gtop-2.0 lm-sensors || fail

  ## IMWhell for GNOME and XFCE
  if [ "${DESKTOP_SESSION:-}" = "ubuntu" ] || [ "${DESKTOP_SESSION:-}" = "ubuntu-wayland" ] || [ "${DESKTOP_SESSION:-}" = "xubuntu" ]; then
    apt::install imwheel || fail
  fi

  ## xcape for XFCE
  if [ "${DESKTOP_SESSION:-}" = "xubuntu" ]; then
    apt::install xcape || fail
  fi

  # Cleanup
  apt::autoremove || fail

  ## The following stuff is installed as user

  # Compile git credential libsecret
  ubuntu::compile-git-credential-libsecret || fail

  # Gnome extensions
  ubuntu::install-corecoding-vitals-gnome-shell-extension || fail

  # Install sway
  if [ -n "${DEPLOY_SWAY:-}" ]; then
    sway::install || fail
  fi
}

ubuntu::apt::install-basic-tools() {
  apt::install \
    curl \
    git \
    jq \
    mc ranger ncdu \
    htop \
    p7zip-full \
    tmux \
    sysbench \
    hwloc-nox \
      || fail
}

ubuntu::apt::install-ruby-and-devtools() {
  apt::install \
    apache2-utils \
    autoconf bison libncurses-dev libffi-dev libgdbm-dev \
    awscli \
    build-essential libreadline-dev libssl-dev zlib1g-dev libyaml-dev libxml2-dev libxslt-dev \
    graphviz \
    imagemagick ghostscript libgs-dev \
    inotify-tools \
    memcached \
    postgresql libpq-dev postgresql-contrib python3-psycopg2 \
    python3-pip \
    redis-server \
    ruby-full \
    shellcheck \
    sqlite3 libsqlite3-dev \
      || fail

  # sudo gem install rake solargraph || fail "Unable to install gems"
  # sudo gem update --system || fail "Unable to execute gem update --system"
  # sudo gem update || fail "Unable to update gems"
}

ubuntu::configure-workstation() {
  # Set inotify-max-user-watches
  ubuntu::set-inotify-max-user-watches || fail

  # hgfs mounts
  ubuntu::perhaps-add-hgfs-automount || fail
  ubuntu::symlink-hgfs-mounts || fail

  # Setup gnome keyring to load for text consoles
  ubuntu::setup-gnome-keyring-pam || fail

  # Fix screen tearing
  ubuntu::perhaps-fix-nvidia-screen-tearing || fail
  # ubuntu::fix-nvidia-gpu-background-image-glitch || fail

  # Desktop configuration
  ubuntu::configure-desktop-apps || fail

  # Remove user dirs
  ubuntu::remove-user-dirs || fail

  # IMWhell for GNOME and XFCE
  if [ "${DESKTOP_SESSION:-}" = "ubuntu" ] || [ "${DESKTOP_SESSION:-}" = "ubuntu-wayland" ] || [ "${DESKTOP_SESSION:-}" = "xubuntu" ]; then
    ubuntu::setup-imwhell || fail
  fi

  # XFCE-specific
  if [ "${DESKTOP_SESSION:-}" = "xubuntu" ]; then
    ubuntu::setup-super-key-to-xfce-menu-workaround || fail
  fi

  # Shell aliases
  deploy-lib::shellrcd::install || fail
  deploy-lib::shellrcd::use-nano-editor || fail
  deploy-lib::shellrcd::stan-computer-deploy-path || fail
  deploy-lib::shellrcd::hook-direnv || fail
  ubuntu::install-shellrcd::gnome-keyring-daemon-start || fail # SSH agent init for text console logins

  # Editors
  vscode::install-config || fail
  vscode::install-extensions || fail
  sublime::install-config || fail

  # SSH keys
  deploy-lib::ssh::install-keys || fail
  ubuntu::add-ssh-key-password-to-keyring || fail

  # Git
  deploy-lib::git::configure || fail
  ubuntu::add-git-credentials-to-keyring || fail

  # Install sway
  if [ -n "${DEPLOY_SWAY:-}" ]; then
    sway::install-config || fail
    sway::install-shellrcd || fail
  fi

  # Ruby
  deploy-lib::ruby::install-gemrc || fail

  # Enable syncthing
  if ubuntu::is-bare-metal; then
    sudo systemctl enable --now "syncthing@${SUDO_USER}.service" || fail
  fi
}

ubuntu::remove-user-dirs() {
  local dirsFile="${HOME}/.config/user-dirs.dirs"

  if [ -f "${dirsFile}" ]; then
    local tmpFile; tmpFile="$(mktemp)" || fail "Unable to create temp file"

    if [ -d "$HOME/Desktop" ]; then
      echo 'XDG_DESKTOP_DIR="$HOME/Desktop"' >>"${tmpFile}" || fail
    fi

    if [ -d "$HOME/Downloads" ]; then
      echo 'XDG_DOWNLOADS_DIR="$HOME/Downloads"' >>"${tmpFile}" || fail
    fi

    mv "${tmpFile}" "${dirsFile}" || fail

    echo 'enabled=false' >"${HOME}/.config/user-dirs.conf" || fail

    deploy-lib::remove-dir-if-empty "$HOME/Documents" || fail
    deploy-lib::remove-dir-if-empty "$HOME/Music" || fail
    deploy-lib::remove-dir-if-empty "$HOME/Pictures" || fail
    deploy-lib::remove-dir-if-empty "$HOME/Public" || fail
    deploy-lib::remove-dir-if-empty "$HOME/Templates" || fail
    deploy-lib::remove-dir-if-empty "$HOME/Videos" || fail

    if [ -f "$HOME/examples.desktop" ]; then
      rm "$HOME/examples.desktop" || fail
    fi

    xdg-user-dirs-update || fail "Unable to perform xdg-user-dirs-update"

    local hiddenFile="${HOME}/.hidden"

    if [ -d "$HOME/Desktop" ] && ! grep --quiet "^Desktop$" "${hiddenFile}"; then
      echo "Desktop" >>"${hiddenFile}" || fail
    fi

    if ! grep --quiet "^snap$" "${hiddenFile}"; then
      echo "snap" >>"${hiddenFile}" || fail
    fi

    if ! grep --quiet "^VirtualBox VMs$" "${hiddenFile}"; then
      echo "VirtualBox VMs" >>"${hiddenFile}" || fail
    fi
  fi
}

ubuntu::configure-desktop-apps() {
  # use dconf-editor to find key/value pairs
  # I don't use dbus-launch here because it will introduce side-effect for ubuntu::add-git-credentials-to-keyring and ubuntu::add-ssh-key-password-to-keyring

  if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    # Terminal
    if gsettings get org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled; then
      gsettings set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false || fail "Unable to set gsettings ($?)"
    fi

    if gsettings get org.gnome.Terminal.ProfilesList default; then
      local terminalProfile; terminalProfile="$(gsettings get org.gnome.Terminal.ProfilesList default)" || fail "Unable to determine terminalProfile ($?)"
      local profilePath="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${terminalProfile:1:-1}/"

      gsettings set "$profilePath" exit-action 'hold' || fail "Unable to set gsettings ($?)"
      gsettings set "$profilePath" login-shell true || fail "Unable to set gsettings ($?)"
    fi

    # Nautilus
    if gsettings list-keys org.gnome.nautilus; then
      gsettings set org.gnome.nautilus.list-view default-zoom-level 'small' || fail "Unable to set gsettings ($?)"
      gsettings set org.gnome.nautilus.list-view use-tree-view true || fail "Unable to set gsettings ($?)"
      gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' || fail "Unable to set gsettings ($?)"
      gsettings set org.gnome.nautilus.preferences show-delete-permanently true || fail "Unable to set gsettings ($?)"
      gsettings set org.gnome.nautilus.preferences show-hidden-files true || fail "Unable to set gsettings ($?)"
    fi

    # Desktop 18.04
    if gsettings list-keys org.gnome.nautilus.desktop; then
      gsettings set org.gnome.nautilus.desktop trash-icon-visible false || fail "Unable to set gsettings ($?)"
      gsettings set org.gnome.nautilus.desktop volumes-visible false || fail "Unable to set gsettings ($?)"
    fi

    # Desktop 19.10
    if gsettings list-keys org.gnome.shell.extensions.desktop-icons; then
      gsettings set org.gnome.shell.extensions.desktop-icons show-trash false || fail "Unable to set gsettings ($?)"
      gsettings set org.gnome.shell.extensions.desktop-icons show-home false || fail "Unable to set gsettings ($?)"
    fi

    # Disable screen lock
    if gsettings get org.gnome.desktop.session idle-delay; then
      gsettings set org.gnome.desktop.session idle-delay 0 || fail "Unable to set gsettings ($?)"
    fi

    # Auto set time zone
    if gsettings get org.gnome.desktop.datetime automatic-timezone; then
      gsettings set org.gnome.desktop.datetime automatic-timezone true || fail "Unable to set gsettings ($?)"
    fi

    # Dash appearance
    if gsettings get org.gnome.shell.extensions.dash-to-dock dash-max-icon-size; then
      gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 38 || fail "Unable to set gsettings ($?)"
    fi

    # Sound alerts
    if gsettings get org.gnome.desktop.sound event-sounds; then
      gsettings set org.gnome.desktop.sound event-sounds false || fail "Unable to set gsettings ($?)"
    fi

    # Mouse
    # 2000 DPI
    # if gsettings get org.gnome.desktop.peripherals.mouse speed; then
    #   gsettings set org.gnome.desktop.peripherals.mouse speed -0.950 || fail "Unable to set gsettings ($?)"
    # fi

    # Input sources
    # ('xkb', 'ru+mac')
    if gsettings get org.gnome.desktop.input-sources sources; then
      gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ru')]" || fail "Unable to set gsettings ($?)"
    fi
  fi
}
