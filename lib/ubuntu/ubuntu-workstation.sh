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

ubuntu-workstation::deploy() {
  # disable screen lock
  ubuntu::desktop::disable-screen-lock || fail

  # update and upgrade
  apt::lazy-update-and-dist-upgrade || fail

  # deploy minimal application server
  ubuntu::deploy-minimal-application-server || fail

  # update nodejs packages
  nodejs::update-globally-installed-packages || fail

  # update ruby packages
  ruby::update-globally-installed-gems || fail

  # increase inotify limits
  linux::configure-inotify || fail

  # gnome-keyring and libsecret (for git and ssh)
  ubuntu::packages::install-gnome-keyring-and-libsecret || fail

  # shellrcd
  shell::install-shellrc-directory-loader "${HOME}/.bashrc" || fail
  shell::install-sopka-path-shellrc || fail

  # bitwarden cli
  bitwarden::install-bitwarden-login-shellrc || fail
  bitwarden::install-cli || fail

  # vscode
  vscode::install-and-configure || fail

  # sublime text and sublime merge
  sublime::apt::install-merge-and-text || fail

  # meld
  apt::install meld || fail

  # chromium
  sudo snap install chromium || fail

  # bitwarden
  sudo snap install bitwarden || fail

  # GNU Privacy Assistant
  apt::install gpa || fail

  # gparted
  apt::install gparted || fail

  # copyq
  # TODO: Check later
  # ubuntu::packages::install-copyq || fail

  # install rclone
  ubuntu::packages::install-rclone || fail

  # whois
  apt::install whois || fail

  # install cifs-utils
  apt::install cifs-utils || fail

  # install restic
  apt::install restic || fail

  # open-vm-tools
  if vmware::is-inside-vm; then
    apt::install open-vm-tools open-vm-tools-desktop || fail
  fi

  # software for bare metal workstation
  if linux::is-bare-metal; then
    ubuntu::packages::install-obs-studio || fail

    apt::install ddccontrol gddccontrol ddccontrol-db i2c-tools || fail

    sudo snap install telegram-desktop || fail
    sudo snap install skype --classic || fail
    sudo snap install discord || fail
  fi

  # configure desktop
  ubuntu-workstation::configure-desktop || fail

  # configure git
  git::configure-user || fail
  git config --global core.autocrlf input || fail

  # install sublime configuration
  sublime::install-config || fail

  # enable systemd user instance without the need for the user to login
  systemd::enable-linger || fail

  # postgresql
  sudo systemctl --now enable postgresql || fail
  postgresql::create-superuser-for-local-account || fail

  # secrets
  if [ -t 0 ]; then
    # the following commands use bitwarden, that requires password entry
    # subshell for unlocked bitwarden
    (
      # secrets
      ubuntu-workstation::deploy-secrets || fail

      # mount host folder
      if vmware::is-inside-vm; then
        ubuntu-workstation::setup-my-folder-mount || fail
      fi
    ) || fail
  fi

  if vmware::is-inside-vm; then
    backup::vm-home-to-host::setup || fail
  fi

  # cleanup
  apt::autoremove || fail

  # set "deployed" flag
  touch "${HOME}/.sopka.workstation.deployed" || fail

  # display footnotes if running on interactive terminal
  tools::perhaps-display-deploy-footnotes || fail
}

ubuntu-workstation::deploy-secrets() {
  # install ssh key, configure ssh to use it
  # bitwarden-object: "my ssh private key", "my ssh public key"
  ssh::install-keys "my" || fail

  # bitwarden-object: "my password for ssh private key"
  ssh::ubuntu::add-key-password-to-keyring "my" || fail

  # git access token
  # bitwarden-object: "my github personal access token"
  git::add-credentials-to-gnome-keyring "my" || fail
  git::use-libsecret-credential-helper || fail

  # rubygems
  # bitwarden-object: "my rubygems credentials"
  bitwarden::write-notes-to-file-if-not-exists "my rubygems credentials" "${HOME}/.gem/credentials" || fail

  # install sublime license key
  sublime::install-license || fail
}

ubuntu-workstation::configure-desktop() {
  # install dconf-editor
  apt::install dconf-editor || fail

  # configure gnome desktop
  if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    ubuntu-workstation::configure-gnome || fail
  fi

  # configure firefox
  ubuntu-workstation::configure-firefox || fail
  firefox::enable-wayland || fail

  # install and configure imwheel
  apt::install imwheel || fail
  ubuntu::desktop::setup-imwhell || fail

  # install vitals gnome shell extension
  if ! vmware::is-inside-vm; then
    if [ -n "${DISPLAY:-}" ]; then
      ubuntu::desktop::install-vitals || fail
    fi
  fi

  # remove user dirs
  ubuntu-workstation::remove-user-dirs || fail

  # hide folders
  ubuntu::desktop::hide-folder "Desktop" "snap" "VirtualBox VMs" || fail

  # apply fixes for nvidia
  if nvidia::is-card-present; then
    nvidia::fix-screen-tearing || fail
    nvidia::fix-gpu-background-image-glitch || fail
  fi
}

# use dconf-editor to find key/value pairs
#
# Don't use dbus-launch here because it will introduce
# side-effect to git::add-credentials-to-gnome-keyring and ssh::ubuntu::add-key-password-to-keyring
#
ubuntu-workstation::configure-gnome() {
  # Enable fractional scaling
  # ubuntu::desktop::enable-fractional-scaling || fail


  # Automatic timezone
  gsettings::perhaps-set org.gnome.desktop.datetime automatic-timezone true || fail


  # Terminal
  gsettings::perhaps-set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false || fail

  if gsettings get org.gnome.Terminal.ProfilesList default >/dev/null; then
    local terminalProfile; terminalProfile="$(gsettings get org.gnome.Terminal.ProfilesList default)" || fail "Unable to determine terminalProfile ($?)"
    local profilePath="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${terminalProfile:1:-1}/"

    gsettings::perhaps-set "$profilePath" exit-action 'hold' || fail
    gsettings::perhaps-set "$profilePath" login-shell true || fail
  fi


  # Nautilus
  gsettings::perhaps-set org.gnome.nautilus.list-view default-zoom-level 'small' || fail
  gsettings::perhaps-set org.gnome.nautilus.list-view use-tree-view true || fail
  gsettings::perhaps-set org.gnome.nautilus.preferences default-folder-viewer 'list-view' || fail
  gsettings::perhaps-set org.gnome.nautilus.preferences show-delete-permanently true || fail
  gsettings::perhaps-set org.gnome.nautilus.preferences show-hidden-files true || fail


  # Desktop
  gsettings::perhaps-set org.gnome.shell.extensions.desktop-icons show-trash false || fail
  gsettings::perhaps-set org.gnome.shell.extensions.desktop-icons show-home false || fail


  # Dash
  gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32 || fail
  gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock dock-fixed false || fail
  gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM' || fail
  gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock hide-delay 0.10000000000000001 || fail
  gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false || fail
  gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true || fail
  gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock show-delay 0.10000000000000001 || fail


  # Disable sound alerts
  gsettings::perhaps-set org.gnome.desktop.sound event-sounds false || fail


  # 1600 DPI mouse
  gsettings::perhaps-set org.gnome.desktop.peripherals.mouse speed -0.75 || fail


  # Input sources
  # on mac host: ('xkb', 'ru+mac')
  gsettings::perhaps-set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ru')]" || fail
}

ubuntu-workstation::configure-firefox() {
  firefox::set-pref "mousewheel.default.delta_multiplier_x" 200 || fail
  firefox::set-pref "mousewheel.default.delta_multiplier_y" 200 || fail
}

ubuntu-workstation::remove-user-dirs() {
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

    dir::remove-if-empty "$HOME/Documents" || fail
    dir::remove-if-empty "$HOME/Music" || fail
    dir::remove-if-empty "$HOME/Pictures" || fail
    dir::remove-if-empty "$HOME/Public" || fail
    dir::remove-if-empty "$HOME/Templates" || fail
    dir::remove-if-empty "$HOME/Videos" || fail

    if [ -f "$HOME/examples.desktop" ]; then
      rm "$HOME/examples.desktop" || fail
    fi

    xdg-user-dirs-update || fail
  fi
}

ubuntu-workstation::setup-my-folder-mount() {
  local hostIpAddress; hostIpAddress="$(vmware::get-host-ip-address)" || fail

  # bitwarden-object: "my microsoft account"
  mount::cifs "//${hostIpAddress}/Users/${USER}/my" "my" "my microsoft account" || fail
}
