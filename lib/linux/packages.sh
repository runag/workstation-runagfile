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

  # shellrc
  shell::install_rc_loader || fail
  shell::install_rc_loader --file ".profile" --dir ".profile.d" || fail
  shell::set_runag_rc || fail
  shell::set_direnv_rc || fail

  # install open-vm-tools
  if vmware::is_inside_vm; then
    apt::install open-vm-tools open-vm-tools-desktop || fail
  fi

  # install terminal-based software
  apt::install \
    apache2-utils \
    awscli \
    certbot \
    direnv \
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
    ssh-import-id \
    tmux \
    whois \
    xclip \
    zsh \
      || fail

  # install restic from github
  restic::install "0.15.2" || fail

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
  ruby::disable_spring || fail
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
  vscode::install::apt || fail

  # sublime text and sublime merge
  sublime_merge::install::apt || fail
  sublime_text::install::apt || fail

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


  ### snap packages

  # chromium
  sudo snap install chromium || fail

  # bitwarden
  sudo snap install bitwarden || fail
  sudo snap connect bitwarden:password-manager-service || fail

  # software for bare metal workstation
  if linux::is_bare_metal; then
    # nvme-cli
    sudo apt-get install nvme-cli || fail

    # vlc
    sudo apt-get install vlc || fail

    # volume control
    sudo apt-get install pavucontrol || fail

    # skype
    sudo snap install skype --classic || fail
    
    # obs studio
    sudo add-apt-repository --yes ppa:obsproject/obs-studio || fail
    apt::update || fail
    apt::install obs-studio || fail

    # spotify
    sudo snap install spotify || fail

    # webcam control
    apt::install v4l-utils || fail

    # discord
    # sudo snap install discord || fail
    # sudo snap connect discord:system-observe || fail

    # copyq
    # sudo add-apt-repository --yes ppa:hluk/copyq || fail
    # apt::update || fail
    # apt::install copyq || fail

    # display control
    # apt::install ddccontrol gddccontrol ddccontrol-db i2c-tools || fail
  fi
}
