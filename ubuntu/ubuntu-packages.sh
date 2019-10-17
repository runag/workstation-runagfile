#!/usr/bin/env bash

#  Copyright 2012-2016 Stanislav Senotrusov <stan@senotrusov.com>
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

apt::update() {
  sudo apt-get -o Acquire::ForceIPv4=true update || fail "Unable to apt-get update ($?)"
}

apt::dist-upgrade() {
  sudo apt-get -o Acquire::ForceIPv4=true -y dist-upgrade || fail "Unable to apt-get dist-upgrade ($?)"
}

apt::autoremove() {
  sudo apt-get -o Acquire::ForceIPv4=true -y autoremove || fail "Unable to apt-get autoremove ($?)"
}

apt::add-key-and-source() {
  local keyUrl="$1"
  local sourceString="$2"
  local sourceName="$3"
  local sourceFile="/etc/apt/sources.list.d/${sourceName}.list"

  curl --fail --silent --show-error "${keyUrl}" | sudo apt-key add -
  test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to get key from ${keyUrl} or import in into apt"

  echo "${sourceString}" | sudo tee "${sourceFile}" || fail "Unable to write apt source into the ${sourceFile}"
}

apt::add-nodejs-source() {
  # Node
  # Please use only even-numbered nodejs releases here, they are LTS
  curl --location --fail --silent --show-error https://deb.nodesource.com/setup_10.x | sudo -E bash -
  test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to curl https://deb.nodesource.com/setup_10.x | bash"
}

apt::add-yarn-source() {
  apt::add-key-and-source "https://dl.yarnpkg.com/debian/pubkey.gpg" "deb https://dl.yarnpkg.com/debian/ stable main" "yarn" || fail "Unable to add yarn apt source"
}

apt::add-syncthing-source() {
  # following https://apt.syncthing.net/
  apt::add-key-and-source "https://syncthing.net/release-key.txt" "deb https://apt.syncthing.net/ syncthing stable" "syncthing" || fail "Unable to add syncthing apt source"
}

apt::install-nodejs-and-yarn() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    yarn \
    nodejs \
      || fail "Unable to apt-get install ($?)"
}

apt::install-basic-tools() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    curl \
    git \
    jq \
    mc ranger ncdu \
    p7zip-full \
    tmux \
    sysbench \
      || fail "Unable to apt-get install ($?)"
}

apt::install-ruby-and-devtools() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    apache2-utils \
    autoconf bison libncurses-dev libffi-dev libgdbm-dev \
    awscli \
    build-essential libreadline-dev libssl-dev zlib1g-dev libyaml-dev libxml2-dev libxslt-dev \
    graphviz \
    imagemagick ghostscript libgs-dev \
    inotify-tools \
    memcached \
    postgresql libpq-dev postgresql-contrib python-psycopg2 \
    python-pip \
    redis-server \
    ruby-full \
    shellcheck \
    sqlite3 libsqlite3-dev \
      || fail "Unable to apt-get install ($?)"
}

ruby::install-system-gems() {
  sudo gem install rake solargraph || fail "Unable to install gems"
  sudo gem update --system || fail "Unable to execute gem update --system"
  sudo gem update || fail "Unable to update gems"
}

apt::install-tor() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    tor \
      || fail "Unable to apt-get install ($?)"
}

apt::install-syncthing() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    syncthing \
      || fail "Unable to apt-get install ($?)"
}

apt::install-ffmpeg() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    ffmpeg \
      || fail "Unable to apt-get install ($?)"
}

apt::install-dconf() {
  # dconf-tools for ubuntu earlier than 19.04
  if [ "$(apt-cache search --names-only dconf-tools | wc -l)" = "0" ]; then
    sudo apt-get install -o Acquire::ForceIPv4=true -y \
      dconf-cli dconf-editor || fail "Unable to apt-get install ($?)"
  else
    sudo apt-get install -o Acquire::ForceIPv4=true -y \
      dconf-tools || fail "Unable to apt-get install ($?)"
  fi
}

apt::install-workstation-tools() {
  # https://wiki.gnome.org/Projects/Libsecret
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    meld \
    xclip \
    imwheel \
    libsecret-tools libsecret-1-0 libsecret-1-dev \
      || fail "Unable to apt-get install ($?)"
}

apt::install-obs-studio() {
  sudo add-apt-repository --yes ppa:obsproject/obs-studio || fail "Unable to add-apt-repository ppa:obsproject/obs-studio ($?)"

  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    obs-studio \
    guvcview \
      || fail "Unable to apt-get install ($?)"
}

snap::install-bitwarden-cli() {
  sudo snap install bw || fail "Unable to snap install ($?)"
}

snap::install-workstation-tools() {
 sudo snap install \
    chromium \
    || fail "Unable to snap install ($?)"
}

snap::install-productivity-workstation-tools() {
  sudo snap install \
    telegram-desktop \
    discord \
    libreoffice \
    bitwarden \
    || fail "Unable to snap install ($?)"

  sudo snap install skype --classic || fail "Unable to snap install ($?)"
}
