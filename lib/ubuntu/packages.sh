#!/usr/bin/env bash

#  Copyright 2012-2020 Stanislav Senotrusov <stan@senotrusov.com>
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

packages::install-vitals() {
  local extensionsDir="${HOME}/.local/share/gnome-shell/extensions"
  local extensionUuid="Vitals@CoreCoding.com"

  apt::install gnome-shell-extensions gir1.2-gtop-2.0 lm-sensors || fail

  mkdir -p "${extensionsDir}" || fail

  git::clone-or-pull "https://github.com/corecoding/Vitals" "${extensionsDir}/${extensionUuid}" || fail

  gnome-extensions enable "${extensionUuid}" || fail
}

packages::install-obs-studio() {
  sudo add-apt-repository --yes ppa:obsproject/obs-studio || fail
  apt::update || fail
  apt::install obs-studio guvcview || fail
}

packages::install-copyq() {
  sudo add-apt-repository --yes ppa:hluk/copyq || fail
  apt::update || fail
  apt::install copyq || fail
}

packages::install-rclone() {
  if ! command -v rclone >/dev/null; then
    curl --fail --silent --show-error https://rclone.org/install.sh | sudo bash
    test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to install rclone"
  fi
}

packages::install-basic-tools() {
  apt::install \
    htop \
    mc \
    ncdu \
    p7zip-full \
    tmux \
      || fail
}

packages::install-developer-tools() {
  apt::install \
    apache2-utils \
    autoconf \
    awscli \
    bison \
    build-essential \
    cloud-guest-utils \
    ffmpeg \
    ghostscript \
    graphviz \
    imagemagick \
    inotify-tools \
    letsencrypt \
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
    memcached \
    nginx \
    postgresql \
    postgresql-contrib \
    python-is-python3 \
    python3 \
    python3-pip \
    python3-psycopg2 \
    redis-server \
    shellcheck \
    sqlite3 \
    zlib1g-dev \
    zsh \
      || fail
}
