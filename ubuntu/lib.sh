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

ubuntu::set-timezone() {
  local timezone="$1"
  sudo timedatectl set-timezone "$timezone"
}

ubuntu::set-locale() {
  local locale="$1"

  sudo locale-gen "$locale"
  sudo update-locale "LANG=$locale" "LANGUAGE=$locale" "LC_CTYPE=$locale" "LC_ALL=$locale"

  export LANG="$locale"
  export LANGUAGE="$locale"
  export LC_CTYPE="$locale"
  export LC_ALL="$locale"
}

ubuntu::fix-nvidia-gpu-background-image-glitch() {
  sudo install --mode=0755 --owner=root --group=root -D -t /usr/lib/systemd/system-sleep ubuntu/background-fix.sh  || { echo "Unable to install ubuntu/background-fix.sh (${?})" >&2; exit 1; }
}

ubuntu::install-my-computer-deploy-shell-alias() {
sudo-write-file /etc/profile.d/my-computer-deploy-shell-alias.sh <<SHELL
  alias my-computer-deploy="${PWD}/bin/shell"
SHELL
}

ubuntu::set-hostname() {
  local hostname="$1"
  local hostnameFile=/etc/hostname

  echo "$hostname" | sudo tee "$hostnameFile"
  test "${PIPESTATUS[*]}" = "0 0" || { echo "Unable to write to $hostnameFile (${?})" >&2; exit 1; }

  sudo hostname --file "$hostnameFile" || { echo "Unable to load hostname from $hostnameFile (${?})" >&2; exit 1; }
}

ubuntu::set-inotify-max-user-watches() {
  local sysctl="/etc/sysctl.conf"

  if [ ! -r "$sysctl" ]; then
    echo "Unable to find file: $sysctl" >&2
    exit 1
  fi

  if grep --quiet "^fs.inotify.max_user_watches" "$sysctl" && grep --quiet "^fs.inotify.max_user_instances" "$sysctl"; then
    echo fs.inotify.max_user_watches and fs.inotify.max_user_instances are already set
  else
    echo fs.inotify.max_user_watches=1000000 | sudo tee --append "$sysctl"
    test "${PIPESTATUS[*]}" = "0 0" || { echo "Unable to write to $sysctl (${?})" >&2; exit 1; }

    echo fs.inotify.max_user_instances=2048 | sudo tee --append "$sysctl"
    test "${PIPESTATUS[*]}" = "0 0" || { echo "Unable to write to $sysctl (${?})" >&2; exit 1; }

    sudo sysctl -p || { echo "Unable to update sysctl config (${?})" >&2; exit 1; }
  fi
}

ubuntu::apt::add-yarn-source() {
  # Yarn
  curl --fail --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  test "${PIPESTATUS[*]}" = "0 0" || { echo "Unable to curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add" >&2; exit 1; }

  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  test "${PIPESTATUS[*]}" = "0 0" || { echo "Unable to wrote to /etc/apt/sources.list.d/yarn.list" >&2; exit 1; }
}

ubuntu::apt::add-nodejs-source() {
  # Node
  # Please use only even-numbered nodejs releases here, they are LTS
  curl --location --fail --silent --show-error https://deb.nodesource.com/setup_10.x | sudo -E bash -
  test "${PIPESTATUS[*]}" = "0 0" || { echo "Unable to curl https://deb.nodesource.com/setup_10.x | bash" >&2; exit 1; }

  # Apt update
  sudo apt-get -o Acquire::ForceIPv4=true update || { echo "Unable to apt-get update (${?})" >&2; exit 1; }
}

ubuntu::apt::update() {
  sudo apt-get -o Acquire::ForceIPv4=true update || { echo "Unable to apt-get update (${?})" >&2; exit 1; }
}

ubuntu::apt::dist-upgrade() {
  sudo apt-get -o Acquire::ForceIPv4=true -y dist-upgrade || { echo "Unable to apt-get dist-upgrade (${?})" >&2; exit 1; }
}

# autoremove packages that are no longer needed
ubuntu::apt::autoremove() {
  sudo apt-get -o Acquire::ForceIPv4=true -y autoremove || { echo "Unable to apt-get autoremove (${?})" >&2; exit 1; }
}

ubuntu::apt::install-basic-tools() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    git \
    tmux \
    curl \
    mc ranger ncdu || { echo "Unable to apt-get install (${?})" >&2; exit 1; }
}

ubuntu::apt::install-ruby-and-devtools() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    postgresql libpq-dev postgresql-contrib \
    sqlite3 libsqlite3-dev \
    build-essential libreadline-dev libssl-dev zlib1g-dev libyaml-dev libxml2-dev libxslt-dev \
    autoconf bison libncurses-dev libffi-dev libgdbm-dev \
    ghostscript libgs-dev imagemagick \
    apache2-utils \
    memcached \
    awscli \
    redis-server \
    ruby-full \
    p7zip-full \
    jq \
    graphviz \
    python-pip \
    inotify-tools \
    shellcheck || { echo "Unable to apt-get install (${?})" >&2; exit 1; }
}

ubuntu::apt::install-nodejs() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    yarn \
    nodejs || { echo "Unable to apt-get install (${?})" >&2; exit 1; }
}

ubuntu::apt::install-gsettings() {
  # dconf-tools for ubuntu earlier than 19.04
  if [ "$(apt-cache search --names-only dconf-tools | wc -l)" = "0" ]; then
    sudo apt-get install -o Acquire::ForceIPv4=true -y \
      dconf-cli dconf-editor || { echo "Unable to apt-get install (${?})" >&2; exit 1; }
  else
    sudo apt-get install -o Acquire::ForceIPv4=true -y \
      dconf-tools || { echo "Unable to apt-get install (${?})" >&2; exit 1; }
  fi
}

ubuntu::configure-desktop-apps() {
  # use dconf-editor to determine key/value pairs

  dbus-launch gsettings set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false || { echo "Unable to set gsettings (${?})" >&2; exit 1; }

  local terminalProfile; terminalProfile="$(gsettings get org.gnome.Terminal.ProfilesList default)" || { echo "Unable to determine terminalProfile (${?})" >&2; exit 1; }
  local profilePath="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${terminalProfile:1:-1}/"

  dbus-launch gsettings set "$profilePath" exit-action 'hold' || { echo "Unable to set gsettings (${?})" >&2; exit 1; }
  dbus-launch gsettings set "$profilePath" login-shell true || { echo "Unable to set gsettings (${?})" >&2; exit 1; }

  dbus-launch gsettings set org.gnome.nautilus.list-view default-zoom-level 'small' || { echo "Unable to set gsettings (${?})" >&2; exit 1; }
  dbus-launch gsettings set org.gnome.nautilus.list-view use-tree-view true || { echo "Unable to set gsettings (${?})" >&2; exit 1; }
  dbus-launch gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' || { echo "Unable to set gsettings (${?})" >&2; exit 1; }
  dbus-launch gsettings set org.gnome.nautilus.preferences show-delete-permanently true || { echo "Unable to set gsettings (${?})" >&2; exit 1; }
  dbus-launch gsettings set org.gnome.nautilus.preferences show-hidden-files true || { echo "Unable to set gsettings (${?})" >&2; exit 1; }
}
