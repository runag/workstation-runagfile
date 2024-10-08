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

workstation::linux::install_packages() (
  # Load operating system identification data
  . /etc/os-release || fail

  # perform autoremove, update and upgrade
  if [ "${ID:-}" = debian ] || [ "${ID_LIKE:-}" = debian ]; then
    apt::autoremove || fail
    apt::update || fail
    apt::dist_upgrade --skip-in-continuous-integration || fail

  elif [ "${ID:-}" = arch ]; then
    sudo pacman --sync --refresh --sysupgrade --noconfirm || fail
  fi

  # tools to use by the rest of the script
  linux::install_runag_essential_dependencies || fail

  # ensure ~/.local/bin exists
  dir::should_exists --mode 0700 "${HOME}/.local" || fail
  dir::should_exists --mode 0700 "${HOME}/.local/bin" || fail

  # install shellfiles
  shellfile::install_loader::bash || fail
  shellfile::install_runag_path_profile --source-now || fail
  shellfile::install_local_bin_path_profile --source-now || fail
  shellfile::install_direnv_rc || fail

  if [ "${ID:-}" = debian ] || [ "${ID_LIKE:-}" = debian ]; then
    local package_list=(
      # general tools
      apache2-utils
      btrfs-compsize
      certbot
      debian-goodies # checkrestart
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
      mc
      micro
      ncdu
      p7zip-full
      rclone
      shellcheck
      sqlite3
      sysbench
      tmux
      whois
      xclip
      xkcdpass
      zsh
      # iperf3

      # build tools
      build-essential
      libsqlite3-dev
      libssl-dev

      # servers
      libpq-dev
      postgresql
      postgresql-contrib
      # memcached
      # redis-server

      # desktop software
      calibre
      dconf-editor
      dosfstools # gparted dependencies for fat partitions
      ghex
      gpa # gnu privacy assistant
      gparted
      imwheel
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

    if [ "${ID:-}" = debian ]; then
      package_list+=(
        awscli
      )
    elif [ "${ID:-}" = ubuntu ]; then
      sudo snap install aws-cli --classic || fail
    fi

    if ! systemd-detect-virt --quiet; then
      # software for bare metal workstation
      package_list+=(
        ddcutil # display control
        nvme-cli
        obs-studio
        pavucontrol # volume control
        v4l-utils # webcam control
        vlc # video player
      )
    elif [ "$(systemd-detect-virt)" = "kvm" ]; then
      # spice-vdagent for kvm
      package_list+=(spice-vdagent)
    
    elif [ "$(systemd-detect-virt)" = "vmware" ]; then
      # open-vm-tools for vmware
      package_list+=(
        open-vm-tools
        open-vm-tools-desktop
      )
    fi

    apt::install "${package_list[@]}" || fail
  
  elif [ "${ID:-}" = arch ]; then
    local package_list=(
      # general tools
      apache
      certbot
      compsize
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
      mc
      micro
      ncdu
      p7zip
      rclone
      shellcheck
      sqlite
      sysbench
      tmux
      whois
      xclip
      zsh
      # iperf3
      # xkcdpass

      # build tools
      base-devel
      openssl

      # servers
      postgresql
      # memcached
      # redis-server

      # cloud
      aws-cli

      # desktop software
      calibre
      dconf-editor
      dosfstools # gparted dependencies for fat partitions
      firefox
      ghex
      gnome-terminal
      gparted
      imwheel
      inkscape
      krita
      libreoffice-fresh
      meld
      mtools # gparted dependencies for fat partitions
      qtpass
      thunar
      ttf-dejavu
      zbar
    )

    if ! systemd-detect-virt --quiet; then
      # software for bare metal workstation
      package_list+=(
        ddcutil # display control
        nvme-cli
        obs-studio
        pavucontrol # volume control
        v4l-utils # webcam control
        vlc # video player
      )
    elif [ "$(systemd-detect-virt)" = "kvm" ]; then
      # spice-vdagent for kvm
      package_list+=(spice-vdagent)
    
    elif [ "$(systemd-detect-virt)" = "vmware" ]; then
      # open-vm-tools for vmware
      package_list+=(
        open-vm-tools
      )
    fi

    sudo pacman --sync --needed --noconfirm "${package_list[@]}" || fail
  fi

  # restic from github
  restic::install "0.16.4" || fail

  # asdf
  asdf::install_dependencies || fail
  asdf::install_with_shellrc || fail

  # nodejs
  nodejs::install_dependencies || fail
  asdf::add_plugin_install_package_and_set_global nodejs || fail

  # ruby
  ruby::dangerously_append_nodocument_to_gemrc || fail
  ruby::install_disable_spring_shellfile || fail
  ruby::install_dependencies || fail
  ruby::without_docs asdf::add_plugin_install_package_and_set_global ruby || fail

  # python
  python::install || fail

  # erlang & elixir
  erlang::install_dependencies || fail
  erlang::install_dependencies::observer || fail
  asdf::add_plugin_install_package_and_set_global erlang || fail
  asdf::add_plugin_install_package_and_set_global elixir || fail
  mix local.hex --if-missing --force || fail
  mix local.rebar --if-missing --force || fail
  mix archive.install hex phx_new --force || fail

  # gnome-keyring and libsecret (for git and ssh)
  # do I need libsecret on arch?
  linux::install_gnome_keyring_and_libsecret || fail

  if [ "${ID:-}" = debian ] || [ "${ID_LIKE:-}" = debian ]; then
    git::install_libsecret_credential_helper || fail
  elif [ "${ID:-}" = arch ]; then
    true
  else
    fail "Unsupported operating system"
  fi

  # micro text editor plugins
  micro -plugin install filemanager || fail

  # vscode
  if [ "${ID:-}" = debian ] || [ "${ID_LIKE:-}" = debian ]; then
    vscode::install::apt || fail
    # sudo snap install code --classic || fail

  elif [ "${ID:-}" = arch ]; then
    # sudo pacman --sync --needed --noconfirm code || fail
    true # TODO: install vscode
  fi

  # sublime text and sublime merge
  sublime_merge::install || fail
  sublime_text::install || fail

  # syncthing
  syncthing::install || fail

  # insall blankfast
  blankfast::install || fail
)
