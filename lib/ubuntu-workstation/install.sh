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
    rclone \
    restic \
    shellcheck \
    sqlite3 \
    ssh-import-id \
    tmux \
    whois \
    zsh \
      || fail
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
  nodejs::install::apt 14 || fail
  nodejs::install-and-load-nodenv || fail

  # update nodejs packages
  nodejs::update-system-wide-packages || fail
}

ubuntu-workstation::install-and-update-ruby() {
  # install rbenv, configure ruby
  ruby::install::apt || fail
  ruby::install-and-load-rbenv || fail
  ruby::dangerously-append-nodocument-to-gemrc || fail

  # update ruby packages
  ruby::update-system-wide-packages || fail
}

ubuntu-workstation::install-and-update-python() {
  apt::install \
    python-is-python3 \
    python3 \
    python3-pip \
    python3-psycopg2 \
      || fail
}

ubuntu-workstation::install-desktop-software::apt() {
  # open-vm-tools-desktop
  if vmware::is-inside-vm; then
    apt::install open-vm-tools-desktop || fail
  fi

  # install dconf-editor
  apt::install dconf-editor || fail

  # sublime text and sublime merge
  sublime-merge::install::apt || fail
  sublime-text::install::apt || fail

  # meld
  apt::install meld || fail

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

    # OBS studio
    ubuntu-workstation::install-obs-studio || fail
  fi
}

ubuntu-workstation::install-desktop-software::snap() {
  # vscode
  vscode::install::snap || fail
  workstation::vscode::install-extensions || fail

  # chromium
  sudo snap install chromium || fail

  # bitwarden
  sudo snap install bitwarden || fail

  # software for bare metal workstation
  if linux::is-bare-metal; then
    # skype
    sudo snap install skype --classic || fail

    # telegram desktop
    sudo snap install telegram-desktop || fail

    # discord
    sudo snap install discord || fail
  fi
}

ubuntu-workstation::install-vitals() {
  apt::install gnome-shell-extensions gir1.2-gtop-2.0 lm-sensors || fail

  local extensionUuid="Vitals@CoreCoding.com"
  local extensionsDir="${HOME}/.local/share/gnome-shell/extensions"

  dir::make-if-not-exists "${HOME}/.local" 755 || fail
  dir::make-if-not-exists "${HOME}/.local/share" 755 || fail
  dir::make-if-not-exists "${HOME}/.local/share/gnome-shell" 700 || fail
  dir::make-if-not-exists "${extensionsDir}" 700 || fail

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

ubuntu-workstation::install-shellrc() {
  shellrc::install-loader "${HOME}/.bashrc" || fail
  shellrc::install-sopka-path-rc || fail
  shellrc::install-nano-editor-rc || fail
}

ubuntu-workstation::install-all-gpg-keys() {
  ubuntu-workstation::install-gpg-key "84C200370DF103F0ADF5028FF4D70B8640424BEA" || fail
}

ubuntu-workstation::install-gpg-key() {
  local key="$1"
  gpg::import-key-with-ultimate-ownertrust "${key}" "/media/${USER}/KEYS-DAILY/keys/gpg/${key:(-8)}/${key:(-8)}-secret-subkeys.asc" || fail
}

ubuntu-workstation::install-bitwarden-cli-and-login() {
  bitwarden::install-cli::snap || fail

  if ! bitwarden::is-logged-in; then
    gpg::decrypt-and-source-script "/media/${USER}/KEYS-DAILY/keys/bitwarden/stan-api-key.sh.asc" || fail
    bitwarden::login --apikey || fail
  fi
}
