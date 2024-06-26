#!/usr/bin/env bash

#  Copyright 2012-2024 Rùnag project contributors
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

  # tools to use by the rest of the script
  linux::install_runag_essential_dependencies::apt || fail

  # shellfiles
  shellfile::install_loader::bash || fail
  shellfile::install_runag_path_profile --source-now || fail
  shellfile::install_direnv_rc || fail

  local package_list=()

  # spice-vdagent for kvm
  if [ "$(systemd-detect-virt)" = "kvm" ]; then
    package_list+=(
      spice-vdagent
    )
  fi

  # open-vm-tools for vmware
  if [ "$(systemd-detect-virt)" = "vmware" ]; then
    package_list+=(
      open-vm-tools
      open-vm-tools-desktop
      imwheel
    )
  fi
  
  package_list+=(
    # general tools
    apache2-utils
    awscli
    btrfs-compsize
    certbot
    direnv
    ethtool
    ffmpeg
    git
    gnupg
    graphviz
    htop
    hyperfine
    imagemagick
    inotify-tools
    iperf3
    mc
    ncdu
    p7zip-full
    rclone
    shellcheck
    sqlite3
    tmux
    sysbench
    whois
    xclip
    xkcdpass
    zsh
    debian-goodies # checkrestart
    micro

    # build tools
    build-essential
    libsqlite3-dev
    libssl-dev

    # servers
    libpq-dev
    # memcached
    postgresql
    postgresql-contrib
    # redis-server

    # desktop software
    calibre
    dconf-editor
    dosfstools # gparted dependencies for fat partitions
    ghex
    gpa # gnu privacy assistant
    gparted
    inkscape
    krita
    libreoffice-calc
    libreoffice-writer
    meld
    mtools # gparted dependencies for fat partitions
    qtpass
    thunar
    zbar-tools
  )

  if ! systemd-detect-virt --quiet; then
    # software for bare metal workstation
    package_list+=(
      nvme-cli
      obs-studio
      pavucontrol # volume control
      v4l-utils # webcam control
      vlc

      # ddccontrol # display control
      # gddccontrol # display control
      # ddccontrol-db # display control
      # i2c-tools # display control
    )
  fi

  apt::install "${package_list[@]}" || softfail || return $?

  # restic from github
  restic::install "0.16.4" || fail

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
  python::install::apt || fail

  # erlang & elixir
  erlang::install_dependencies::apt || fail
  erlang::install_dependencies::observer::apt || fail
  asdf::add_plugin_install_package_and_set_global erlang || fail
  asdf::add_plugin_install_package_and_set_global elixir || fail
  mix local.hex --if-missing --force || fail
  mix local.rebar --if-missing --force || fail
  mix archive.install hex phx_new --force || fail

  # gnome-keyring and libsecret (for git and ssh)
  linux::install_gnome_keyring_and_libsecret::apt || fail
  git::install_libsecret_credential_helper || fail

  # micro text editor plugins
  micro -plugin install filemanager || fail

  # vscode
  vscode::install::apt || fail

  # sublime text and sublime merge
  sublime_merge::install::apt || fail
  # sublime_text::install::apt || fail

  # syncthing
  syncthing::install::apt || fail
}
