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
  if [ -t 1 ]; then
    ubuntu::display-if-restart-required || fail
    tools::display-elapsed-time || fail
  fi
}

ubuntu::install-packages() {
  # update and upgrade
  apt::update || fail
  apt::dist-upgrade || fail

  # basic tools, contains curl so it have to be first
  ubuntu::packages::install-basic-tools || fail

  # devtools
  ubuntu::packages::install-devtools || fail

  # git credential libsecret
  git::ubuntu::install-credential-libsecret || fail

  # bitwarden cli
  sudo snap install bw || fail

  # ruby
  ruby::install-rbenv || fail

  # nodejs
  apt::add-yarn-source || fail
  apt::add-nodejs-source || fail
  apt::update || fail
  apt::install yarn nodejs || fail
  nodejs::install-nodenv || fail

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
  if ubuntu::vmware::is-inside-vm; then
    apt::install open-vm-tools open-vm-tools-desktop || fail
  fi

  # imwheel
  apt::install imwheel || fail

  # gnome configuration
  apt::install dconf-cli dconf-editor libglib2.0-bin || fail

  # corecoding-vitals-gnome-shell-extension
  # disabled to see if it cause screen freeze problem or not
  # ubuntu::desktop::install-corecoding-vitals-gnome-shell-extension || fail

  # software for bare metal workstation
  if ubuntu::is-bare-metal; then
    # apt::add-syncthing-source || fail
    apt::add-obs-studio-source || fail

    apt::update || fail

    # apt::install syncthing || fail
    apt::install obs-studio guvcview || fail

    sudo snap install bitwarden || fail
    sudo snap install discord || fail
    sudo snap install skype --classic || fail
    sudo snap install telegram-desktop || fail
  fi

  # Cleanup
  apt::autoremove || fail
}

ubuntu::configure-workstation() {
  # increase inotify limits
  ubuntu::set-inotify-max-user-watches || fail

  # shellrcd
  shellrcd::install || fail
  shellrcd::use-nano-editor || fail
  shellrcd::sopka-src-path || fail
  shellrcd::hook-direnv || fail

  # ruby
  ruby::configure-gemrc || fail
  shellrcd::rbenv || fail
  rbenv rehash || fail
  sudo gem update || fail

  # nodejs
  shellrcd::nodenv || fail
  nodenv rehash || fail

  # vscode
  vscode::install-config || fail
  vscode::install-extensions || fail

  # sublime text
  sublime::install-config || fail

  # enable syncthing
  # if ubuntu::is-bare-metal; then
  #   sudo systemctl enable --now "syncthing@${SUDO_USER}.service" || fail
  # fi

  # configure desktop
  ubuntu::desktop::configure || fail

  # IMWhell
  ubuntu::desktop::setup-imwhell || fail

  # NVIDIA fixes
  if ubuntu::nvidia::is-card-present; then
    ubuntu::nvidia::fix-screen-tearing || fail
    ubuntu::nvidia::fix-gpu-background-image-glitch || fail
  fi

  # enable wayland for firefox
  ubuntu::desktop::moz-enable-wayland || fail

  # remove user dirs
  ubuntu::desktop::remove-user-dirs || fail

  # hide folders
  ubuntu::desktop::hide-folder "Desktop" || fail
  ubuntu::desktop::hide-folder "snap" || fail
  ubuntu::desktop::hide-folder "VirtualBox VMs" || fail

  # hgfs mounts
  if ubuntu::vmware::is-inside-vm; then
    ubuntu::vmware::add-hgfs-automount || fail
    ubuntu::vmware::symlink-hgfs-mounts || fail
  fi

  # SSH keys
  ssh::install-keys || fail
  ssh::ubuntu::add-key-password-to-keyring || fail

  # git
  git::configure || fail
  git::ubuntu::add-credentials-to-keyring || fail
}
