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
  # disable screen lock
  ubuntu::desktop::disable-screen-lock || fail

  # update and upgrade
  apt::update || fail
  apt::dist-upgrade || fail

  # increase inotify limits
  ubuntu::set-inotify-max-user-watches || fail

  # basic tools, contains curl so it have to be first
  ubuntu::packages::install-basic-tools || fail

  # devtools
  ubuntu::packages::install-devtools || fail

  # bitwarden and bitwarden cli
  sudo snap install bitwarden || fail
  sudo snap install bw || fail

  # gnome-keyring and libsecret (for git and ssh)
  apt::install gnome-keyring libsecret-tools libsecret-1-0 libsecret-1-dev || fail
  git::ubuntu::install-credential-libsecret || fail

  # shellrcd
  shellrcd::install || fail
  shellrcd::use-nano-editor || fail
  shellrcd::sopka-lib-path || fail
  shellrcd::hook-direnv || fail
  bitwarden::shellrcd::set-bitwarden-login || fail

  # ruby
  ruby::configure-gemrc || fail
  ruby::install-rbenv || fail
  shellrcd::rbenv || fail
  rbenv rehash || fail
  sudo gem update || fail

  # nodejs
  apt::add-yarn-source || fail
  apt::add-nodejs-source || fail
  apt::update || fail
  apt::install yarn nodejs || fail
  nodejs::install-nodenv || fail
  shellrcd::nodenv || fail
  nodenv rehash || fail

  # vscode
  vscode::snap::install || fail
  vscode::install-config || fail
  vscode::install-extensions || fail

  # sublime text and sublime merge
  sublime::apt::add-sublime-source || fail
  apt::update || fail
  sublime::apt::install-sublime-merge || fail
  sublime::apt::install-sublime-text || fail

  # meld
  apt::install meld || fail

  # chromium
  sudo snap install chromium || fail

  # open-vm-tools
  if ubuntu::vmware::is-inside-vm; then
    apt::install open-vm-tools open-vm-tools-desktop || fail
    ubuntu::vmware::add-hgfs-automount || fail
    ubuntu::vmware::symlink-hgfs-mounts || fail
  fi

  # syncthing
  if [ "${INSTALL_SYNCTHING:-}" = true ]; then
    apt::add-syncthing-source || fail
    apt::update || fail
    apt::install syncthing || fail
    sudo systemctl enable --now "syncthing@${SUDO_USER}.service" || fail
  fi

  # software for bare metal workstation
  if ubuntu::is-bare-metal; then
    apt::add-obs-studio-source || fail
    apt::update || fail
    apt::install obs-studio guvcview || fail

    sudo snap install telegram-desktop || fail
    sudo snap install skype --classic || fail
    sudo snap install discord || fail
  fi

  # configure desktop
  ubuntu::desktop::configure || fail

  # cleanup
  apt::autoremove || fail

  # the following commands use bitwarden and that requires password entry
  (
    # sublime license key
    sublime::install-config || fail

    # ssh
    ssh::install-keys || fail
    ssh::ubuntu::add-key-password-to-keyring || fail

    # git
    git::configure || fail
    git::ubuntu::add-credentials-to-keyring || fail
  ) || fail

  if [ -t 1 ]; then
    ubuntu::display-if-restart-required || fail
    tools::display-elapsed-time || fail
  fi
}
