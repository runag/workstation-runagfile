#!/usr/bin/env bash

#  Copyright 2012-2022 Rùnag project contributors
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

workstation::linux::install_packages() {
  # perform autoremove, update and upgrade
  apt::autoremove || fail
  apt::update || fail
  apt::dist_upgrade --skip-in-continuous-integration || fail

  # install tools to use by the rest of the script
  linux::install_runag_essential_dependencies::apt || fail

  # shellfiles
  shellfiles::install_loader::bash || fail
  shellfiles::install_runag_path_profile || fail
  shellfiles::install_direnv_rc || fail

  # install open-vm-tools
  if vmware::is_inside_vm; then
    apt::install open-vm-tools open-vm-tools-desktop || fail
  fi

  # install misc tools
  apt::install \
    apache2-utils \
    awscli \
    certbot \
    direnv \
    ethtool \
    ffmpeg \
    git \
    gnupg \
    graphviz \
    hexdiff \
    htop \
    hyperfine \
    imagemagick \
    iperf3 \
    mc \
    ncdu \
    p7zip-full \
    rclone \
    shellcheck \
    sqlite3 \
    tmux \
    whois \
    xclip \
    xkcdpass \
    zsh \
      || fail

  # install restic from github
  restic::install "0.16.4" || fail

  # install inotify tools
  apt::install inotify-tools || fail

  # gparted dependencies for fat partitions
  apt::install dosfstools mtools || fail

  # install build tools
  apt::install \
    build-essential \
    libsqlite3-dev \
    libssl-dev \
      || fail

  # install servers
  apt::install memcached || fail
  apt::install postgresql postgresql-contrib libpq-dev || fail
  apt::install redis-server || fail

  # install btrfs-compsize
  apt::install btrfs-compsize || fail

  # asdf
  asdf::install_dependencies::apt || fail
  asdf::install_with_shellrc || fail

  # nodejs
  nodejs::install_dependencies::apt || fail
  asdf::add_plugin_install_package_and_set_global nodejs || fail

  # ruby
  ruby::dangerously_append_nodocument_to_gemrc || fail
  ruby::install_disable_spring_shellfile || fail
  ruby::install_dependencies::apt || fail
  ruby::without_docs asdf::add_plugin_install_package_and_set_global ruby || fail

  # python
  python::install_and_update::apt || fail

  # erlang & elixir
  erlang::install_dependencies::apt || fail
  erlang::install_dependencies::observer::apt || fail
  asdf::add_plugin_install_package_and_set_global erlang || fail
  asdf::add_plugin_install_package_and_set_global elixir || fail
  mix local.hex --if-missing --force || fail
  mix local.rebar --if-missing --force || fail
  mix archive.install hex phx_new --force || fail

  # install gnome-keyring and libsecret (for git and ssh)
  linux::install_gnome_keyring_and_libsecret::apt || fail
  git::install_libsecret_credential_helper || fail

  # install benchmark
  benchmark::install::apt || fail

  # install checkrestart for use in linux::display_if_restart_required
  linux::display_if_restart_required::install::apt || fail

  # micro text editor
  apt::install micro || fail
  micro -plugin install filemanager || fail


  ### desktop software

  # inkscape
  apt::install inkscape || fail

  # krita
  apt::install krita || fail

  # libreoffice
  apt::install libreoffice-writer libreoffice-calc || fail

  # calibre
  apt::install calibre || fail

  # vscode
  # vscode::install::apt || fail
  vscode::install::snap || fail

  # sublime text and sublime merge
  sublime_merge::install::apt || fail
  # sublime_text::install::apt || fail

  # ghex
  apt::install ghex || fail

  # meld
  apt::install meld || fail

  # thunar
  apt::install thunar || fail

  # qtpass
  apt::install qtpass || fail

  # gparted
  apt::install gparted || fail

  # gnu privacy assistant
  apt::install gpa || fail

  # install dconf-editor
  apt::install dconf-editor || fail

  # imwheel
  if vmware::is_inside_vm; then
    apt::install imwheel || fail
  fi

  # gnome-screenshot
  apt::install gnome-screenshot || fail

  # gnome-shell-extension-manager
  apt::install gnome-shell-extension-manager || fail

  # zbar-tools
  apt::install zbar-tools || fail

  ### snap packages

  # chromium
  sudo snap install chromium || fail

  # software for bare metal workstation
  if linux::is_bare_metal; then
    # nvme-cli
    apt::install nvme-cli || fail

    # volume control
    apt::install pavucontrol || fail

    # webcam control
    apt::install v4l-utils || fail

    # vlc
    apt::install vlc || fail

    # obs studio
    sudo add-apt-repository --yes ppa:obsproject/obs-studio || fail
    apt::update || fail
    apt::install obs-studio || fail

    # display control
    # apt::install ddccontrol gddccontrol ddccontrol-db i2c-tools || fail
  fi
}
