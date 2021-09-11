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

ubuntu-workstation::install-terminal-software() {
  apt::install \
    apache2-utils \
    awscli \
    certbot \
    ffmpeg \
    git \
    gnupg \
    graphviz \
    htop \
    imagemagick \
    iperf3 \
    mc \
    ncdu \
    p7zip-full \
    restic \
    shellcheck \
    sqlite3 \
    ssh-import-id \
    tmux \
    whois \
    zsh \
      || fail

  rclone::install || fail
}

ubuntu-workstation::install-build-tools() {
  apt::install \
    build-essential \
    libsqlite3-dev \
    libssl-dev \
      || fail
}

ubuntu-workstation::install-servers() {
  apt::install memcached || fail
  apt::install postgresql postgresql-contrib libpq-dev || fail
  apt::install redis-server || fail
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
  if [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then
    apt::install imwheel || fail
  fi

  # software for bare metal workstation
  if linux::is-bare-metal; then
    # copyq
    ubuntu-workstation::install-copyq || fail

    # hardware monitoring
    apt::install ddccontrol gddccontrol ddccontrol-db i2c-tools || fail
    ubuntu-workstation::install-vitals || fail

    # skype
    sudo snap install skype --classic || fail

    # telegram desktop
    sudo snap install telegram-desktop || fail

    # discord
    sudo snap install discord || fail

    # OBS studio
    ubuntu-workstation::install-obs-studio || fail
  fi
}

ubuntu-workstation::install-vitals() {
  local extensionsDir="${HOME}/.local/share/gnome-shell/extensions"
  local extensionUuid="Vitals@CoreCoding.com"

  apt::install gnome-shell-extensions gir1.2-gtop-2.0 lm-sensors || fail

  mkdir -p "${extensionsDir}" || fail

  git::place-up-to-date-clone "https://github.com/corecoding/Vitals" "${extensionsDir}/${extensionUuid}" || fail

  gnome-extensions enable "${extensionUuid}" || fail
}

ubuntu-workstation::install-copyq() {
  sudo add-apt-repository --yes ppa:hluk/copyq || fail
  apt::update || fail
  apt::install copyq || fail
}

ubuntu-workstation::install-obs-studio() {
  sudo add-apt-repository --yes ppa:obsproject/obs-studio || fail
  apt::update || fail
  apt::install obs-studio guvcview || fail
}

ubuntu-workstation::install-all-gpg-keys() {
  ubuntu-workstation::install-gpg-key "84C200370DF103F0ADF5028FF4D70B8640424BEA" || fail
}

ubuntu-workstation::install-gpg-key() {
  local key="$1"
  keys::install-gpg-key "${key}" "/media/${USER}/KEYS-DAILY/keys/gpg/${key:(-8)}/${key:(-8)}-secret-subkeys.asc" || fail
}
