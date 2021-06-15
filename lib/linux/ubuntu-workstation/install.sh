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

ubuntu-workstation::install-system-software() {
  # install open-vm-tools
  if vmware::is-inside-vm; then
    apt::install open-vm-tools || fail
  fi

  # install cloud guest utils
  apt::install cloud-guest-utils || fail

  # install inotify tools
  apt::install inotify-tools || fail

  # install cifs-utils
  apt::install cifs-utils || fail
}

ubuntu-workstation::install-shellrc() {
  shell::install-shellrc-directory-loader "${HOME}/.bashrc" || fail
  shell::install-sopka-path-shellrc || fail
  shell::install-nano-editor-shellrc || fail
  shell::install-direnv-loader-shellrc || fail
}

ubuntu-workstation::install-terminal-software() {
  # install git
  apt::install git || fail

  # install rclone
  rclone::install || fail

  # install restic
  apt::install restic || fail

  # file managers
  apt::install mc ncdu || fail
  
  # p7zip
  apt::install p7zip-full || fail

  # htop
  apt::install htop || fail

  # tmux
  apt::install tmux || fail

  # iperf3, network speed test
  apt::install iperf3 || fail

  # whois
  apt::install whois || fail

  # apache2-utils
  apt::install apache2-utils || fail

  # awscli
  apt::install awscli || fail

  # ffmpeg
  apt::install ffmpeg || fail

  # ghostscript
  apt::install ghostscript || fail

  # graphviz
  apt::install graphviz || fail

  # imagemagick
  apt::install imagemagick || fail

  # letsencrypt
  apt::install letsencrypt || fail

  # shellcheck
  apt::install shellcheck || fail

  # sqlite3
  apt::install sqlite3 || fail

  # zsh
  apt::install zsh || fail
}

ubuntu-workstation::install-build-tools() {
  apt::install \
    autoconf \
    bison \
    build-essential \
    libffi-dev \
    libgdbm-dev \
    libgs-dev \
    libncurses-dev \
    libpq-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libxslt-dev \
    libyaml-dev \
    zlib1g-dev \
      || fail
}

ubuntu-workstation::install-and-configure-servers() {
  apt::install memcached || fail
  apt::install redis-server || fail
  apt::install nginx || fail

  # postgresql
  apt::install postgresql postgresql-contrib || fail
  sudo systemctl --now enable postgresql || fail
  postgresql::create-superuser-for-local-account || fail
}

ubuntu-workstation::install-and-update-nodejs() {
    # install nodejs
  nodejs::apt::install || fail
  nodejs::install-and-load-nodenv || fail

  # update nodejs packages
  nodejs::update-globally-installed-packages || fail
}

ubuntu-workstation::install-and-update-ruby() {
  # install rbenv, configure ruby
  ruby::apt::install || fail
  ruby::install-and-load-rbenv || fail
  ruby::dangerously-append-nodocument-to-gemrc || fail

  # update ruby packages
  ruby::update-globally-installed-gems || fail
}

ubuntu-workstation::install-and-update-python() {
  apt::install \
    python-is-python3 \
    python3 \
    python3-pip \
    python3-psycopg2 \
      || fail
}

ubuntu-workstation::install-desktop-software() {
  # open-vm-tools-desktop
  if vmware::is-inside-vm; then
    apt::install open-vm-tools-desktop || fail
  fi

  # install dconf-editor
  apt::install dconf-editor || fail

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

  # gparted
  apt::install gparted || fail

  # GNU Privacy Assistant
  apt::install gpa || fail

  # imwheel 
  apt::install imwheel || fail

  # software for bare metal workstation
  if linux::is-bare-metal; then
    # OBS studio
    ubuntu-workstation::install-obs-studio || fail

    # copyq
    ubuntu-workstation::install-copyq || fail

    # hardware monitoring
    apt::install ddccontrol gddccontrol ddccontrol-db i2c-tools || fail
    ubuntu-workstation::install-vitals || fail

    # telegram desktop
    sudo snap install telegram-desktop || fail

    # skype
    sudo snap install skype --classic || fail

    # discord
    sudo snap install discord || fail
  fi
}

ubuntu-workstation::install-secrets-software() {
  # gnome-keyring and libsecret (for git and ssh)
  apt::install-gnome-keyring-and-libsecret || fail
  git::install-libsecret-credential-helper || fail

  # bitwarden cli
  bitwarden::install-bitwarden-login-shellrc || fail
  bitwarden::install-cli || fail
}

ubuntu-workstation::install-vitals() {
  local extensionsDir="${HOME}/.local/share/gnome-shell/extensions"
  local extensionUuid="Vitals@CoreCoding.com"

  apt::install gnome-shell-extensions gir1.2-gtop-2.0 lm-sensors || fail

  mkdir -p "${extensionsDir}" || fail

  git::clone-or-pull "https://github.com/corecoding/Vitals" "${extensionsDir}/${extensionUuid}" || fail

  gnome-extensions enable "${extensionUuid}" || fail
}

ubuntu-workstation::install-obs-studio() {
  sudo add-apt-repository --yes ppa:obsproject/obs-studio || fail
  apt::update || fail
  apt::install obs-studio guvcview || fail
}

ubuntu-workstation::install-copyq() {
  sudo add-apt-repository --yes ppa:hluk/copyq || fail
  apt::update || fail
  apt::install copyq || fail
}
