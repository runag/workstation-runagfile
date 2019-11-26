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

ubuntu::install-packages() {
  # Update the system
  apt::update || fail
  apt::perhaps-install-mbpfan || fail
  apt::dist-upgrade || fail

  # Basic tools, contains curl so it have to be first
  apt::install-basic-tools || fail

  # Additional sources
  apt::add-yarn-source || fail
  apt::add-nodejs-source || fail
  sublime::apt::add-sublime-source || fail
  if ubuntu::is-bare-metal; then
    apt::add-syncthing-source || fail
    apt::add-obs-studio-source || fail
  fi
  apt::update || fail

  # Command-line tools
  apt::install-ruby-and-devtools || fail
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
  sudo snap install chromium || fail "Unable to snap install ($?)"


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

  # dconf
  apt::install-dconf || fail

  # gsettings
  apt::install libglib2.0-bin || fail

  # https://wiki.gnome.org/Projects/Libsecret
  apt::install gnome-keyring libsecret-tools libsecret-1-0 libsecret-1-dev || fail

  # I no longer use dbus-launch because because it will introduce side-effect for ubuntu::add-git-credentials-to-keyring and ubuntu::add-ssh-key-password-to-keyring
  # apt::install dbus-x11 || fail

  # open-vm-tools
  apt::perhaps-install-open-vm-tools-desktop || fail

  # for corecoding-vitals-gnome-shell-extension
  apt::install gir1.2-gtop-2.0 lm-sensors || fail

  # IMWhell for GNOME and XFCE
  if [ "${DESKTOP_SESSION:-}" = "ubuntu" ] || [ "${DESKTOP_SESSION:-}" = "ubuntu-wayland" ] || [ "${DESKTOP_SESSION:-}" = "xubuntu" ]; then
    apt::install imwheel || fail
  fi

  # xcape for XFCE
  if [ "${DESKTOP_SESSION:-}" = "xubuntu" ]; then
    apt::install xcape || fail
  fi


  # Cleanup
  apt::autoremove || fail
}

apt::install-basic-tools() {
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

apt::install-ruby-and-devtools() {
  apt::install \
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
      || fail

  # sudo gem install rake solargraph || fail "Unable to install gems"
  # sudo gem update --system || fail "Unable to execute gem update --system"
  # sudo gem update || fail "Unable to update gems"
}

apt::update() {
  sudo apt-get -o Acquire::ForceIPv4=true update || fail "Unable to apt-get update ($?)"
}

apt::dist-upgrade() {
  sudo apt-get -o Acquire::ForceIPv4=true -y dist-upgrade || fail "Unable to apt-get dist-upgrade ($?)"
}

apt::install() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y "$@" || fail "Unable to apt-get install $* ($?)"
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

apt::add-obs-studio-source() {
  sudo add-apt-repository --yes ppa:obsproject/obs-studio || fail "Unable to add-apt-repository ppa:obsproject/obs-studio ($?)"
}

apt::perhaps-install-mbpfan() {
  if sudo dmidecode --string baseboard-version | grep --quiet "MacBookAir5\\,2"; then
    apt::install mbpfan || fail
  fi 
}

apt::perhaps-install-open-vm-tools-desktop() {
  if sudo dmidecode -t system | grep --quiet "Product\\ Name\\:\\ VMware\\ Virtual\\ Platform"; then
    apt::install open-vm-tools open-vm-tools-desktop || fail
  fi
}

apt::install-dconf() {
  # dconf-tools for ubuntu earlier than 19.04
  if [ "$(apt-cache search --names-only dconf-tools | wc -l)" = "0" ]; then
    apt::install dconf-cli dconf-editor || fail
  else
    apt::install dconf-tools || fail
  fi
}

ubuntu::install-senotrusov-backup-script() (
  deploy-lib::git::cd-to-temp-clone "https://github.com/senotrusov/backup-script" || fail
  ./backup-script install || fail
  deploy-lib::git::remove-temp-clone || fail
)

ubuntu::install-corecoding-vitals-gnome-shell-extension() {
  local extensionsDir="${HOME}/.local/share/gnome-shell/extensions"
  local extensionUuid="Vitals@CoreCoding.com"

  mkdir -p "${extensionsDir}" || fail

  deploy-lib::git::make-repository-clone-available "https://github.com/corecoding/Vitals" "${extensionsDir}/${extensionUuid}" || fail

  gnome-extensions enable "${extensionUuid}" || fail
}
