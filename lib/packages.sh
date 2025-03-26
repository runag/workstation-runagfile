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

  # install packages
  if [ "${ID:-}" = debian ] || [ "${ID_LIKE:-}" = debian ]; then
    workstation::linux::install_packages::debian || fail

  elif [ "${ID:-}" = arch ]; then
    workstation::linux::install_packages::arch || fail
  fi

  # ensure ~/.local/bin exists
  dir::ensure_exists --mode 0700 "${HOME}/.local/bin" || fail

  # install shellfiles
  shellfile::install_loader::bash || fail
  shellfile::install_runag_path_profile --source-now || fail
  shellfile::install_local_bin_path_profile --source-now || fail
  shellfile::install_direnv_rc || fail

  # asdf
  asdf::install_self || fail
  asdf::install_shellfile || fail
  asdf::load || fail

  # nodejs
  asdf::install --global nodejs || fail

  # ruby
  ruby::dangerously_append_nodocument_to_gemrc || fail
  ruby::install_disable_spring_shellfile || fail
  ruby::without_docs asdf::install --global ruby || fail

  # erlang & elixir
  asdf::install --global erlang || fail
  asdf::install --global elixir "1.18.3-otp-27" || fail
  mix local.hex --if-missing --force || fail
  mix local.rebar --if-missing --force || fail
  mix archive.install hex phx_new --force || fail

  # gnome-keyring and libsecret (for git and ssh)
  linux::install_gnome_keyring_and_libsecret || fail

  # install libsecret credential helper for git
  if [ "${ID:-}" = debian ] || [ "${ID_LIKE:-}" = debian ]; then
    git::install_libsecret_credential_helper || fail
  fi

  # install micro text editor plugins
  # micro -plugin install filemanager || fail

  # install vscode
  if [ "${ID:-}" = debian ] || [ "${ID_LIKE:-}" = debian ]; then
    vscode::install::apt || fail
    # sudo snap install code --classic || fail
  elif [ "${ID:-}" = arch ]; then
    true # TODO: install vscode
    # sudo pacman --sync --needed --noconfirm code || fail
  fi

  # install sublime text and sublime merge
  sublime_merge::install || fail
  sublime_text::install || fail

  # install syncthing
  syncthing::install || fail

  # install pass fzf plugin
  pass::install_fzf_extension || fail

  # enable services
  sudo systemctl --now enable tailscaled || fail
)

workstation::linux::install_packages::debian() (
  # Load operating system identification data
  . /etc/os-release || fail

  if [ "${CI:-}" = "true" ]; then
    apt::update || fail
  else
    apt::update || fail
    apt::autoremove || fail
    apt::upgrade || fail
  fi

  tailscale::add_apt_source || fail

  local package_list=(
    # == Desktop: browsers ==

    # == Desktop: text editors ==
    ghex
    meld

    # == Desktop: content creation and productivity ==
    # inkscape
    # obs-studio
    krita
    libreoffice-calc
    libreoffice-writer

    # == Desktop: content consumption ==
    calibre
    vlc

    # == Desktop: misc tools ==
    # gpa # gnu privacy assistant
    # gparted
    # thunar
    dconf-editor
    qtpass

    # == Desktop: fonts ==

    # == Desktop: hardware ==
    # ddcutil # display control
    # pavucontrol # volume control
    imwheel # mouse wheel
    v4l-utils # webcam control

    # == Terminal ui ==
    # debian-goodies # checkrestart
    # htop
    direnv
    mc
    micro
    ncdu
    tmux
    xclip
    xkcdpass
    zsh

    # == Build and developer tools ==
    # inotify-tools
    build-essential
    gawk
    git
    gnupg
    libsqlite3-dev
    libssl-dev
    pipx
    python-is-python3
    python3
    shellcheck

    # == Databases and servers ==
    # memcached
    # redis-server
    libpq-dev
    postgresql
    postgresql-contrib
    sqlite3

    # == Cloud and networking ==
    # ethtool
    certbot
    tailscale
    whois

    # == Batch media processing ==
    # graphviz
    ffmpeg
    imagemagick
    zbar-tools

    # == Storage and files ==
    # btrfs-compsize
    # dosfstools # gparted dependencies for fat partitions
    # mtools # gparted dependencies for fat partitions
    # rclone
    nvme-cli
    p7zip-full

    # == Benchmarks ==
    # apache2-utils
    # hyperfine
    # iperf3
    # sysbench
  )

  # Populate the `package_list` array with dependencies
  runag::extend_package_list::debian || fail
  asdf::extend_package_list::debian || fail
  erlang::extend_package_list::debian || fail
  erlang::extend_package_list::observer::debian || fail
  ruby::extend_package_list::debian || fail
  nodejs::extend_package_list::debian || fail

  if [ "${ID:-}" = debian ]; then
    package_list+=(awscli)
  fi

  if [ "$(systemd-detect-virt)" = "kvm" ]; then
    package_list+=(spice-vdagent)
  fi

  apt::install "${package_list[@]}" || fail

  # Install aws-cli via snap for Ubuntu.
  if [ "${ID:-}" = ubuntu ]; then
    sudo snap install aws-cli --classic || fail
  fi

  # Install restic from github.
  restic::install "0.17.3" || fail
)

workstation::linux::install_packages::arch() {
  sudo pacman --sync --clean --noconfirm || fail
  sudo pacman --sync --sysupgrade --refresh --noconfirm || fail

  local package_list=(
    # == Desktop: browsers ==
    chromium
    firefox

    # == Desktop: messengers ==

    # == Desktop: text editors ==
    ghex
    meld

    # == Desktop: content creation and productivity ==
    # inkscape
    # obs-studio
    krita
    libreoffice-fresh

    # == Desktop: content consumption ==
    calibre
    vlc

    # == Desktop: misc tools ==
    # gparted
    # thunar
    dconf-editor
    gnome-terminal
    qtpass

    # == Desktop: fonts ==
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    ttf-dejavu

    # == Desktop: hardware ==
    # ddcutil # display control
    # pavucontrol # volume control
    cameractrls # webcam control gui
    imwheel # mouse wheel
    v4l-utils # webcam control

    # == Terminal ui ==
    # htop
    direnv
    fzf
    mc
    micro
    ncdu
    tmux
    xclip
    xkcdpass
    zsh

    # == Build and developer tools ==
    # inotify-tools
    base-devel
    gawk
    git
    gnupg
    openssl
    python
    python-pipx
    shellcheck

    # == Databases and servers ==
    # memcached
    # redis-server
    postgresql
    postgresql-old-upgrade
    sqlite

    # == Cloud and networking ==
    # ethtool
    aws-cli
    certbot
    tailscale
    whois

    # == Virtual machines ==
    incus

    # == Batch media processing ==
    # graphviz
    ffmpeg
    imagemagick
    zbar

    # == Storage and files ==
    # compsize
    # dosfstools # gparted dependencies for fat partitions
    # mtools # gparted dependencies for fat partitions
    # rclone
    nvme-cli
    p7zip
    restic

    # == Benchmarks ==
    # apache
    # fio
    # hyperfine
    # iperf3
    # sysbench
  )

  # Populate the `package_list` array with dependencies
  runag::extend_package_list::arch || fail
  asdf::extend_package_list::arch || fail
  erlang::extend_package_list::arch || fail
  erlang::extend_package_list::observer::arch || fail
  ruby::extend_package_list::arch || fail
  nodejs::extend_package_list::arch || fail

  # software for kvm
  if [ "$(systemd-detect-virt)" = "kvm" ]; then
    package_list+=(spice-vdagent)
  fi

  sudo pacman --sync --needed --noconfirm "${package_list[@]}" || fail

  # patch things for restic
  if ! command -v fusermount >/dev/null; then
    ln -s /bin/fusermount3 ~/.local/bin/fusermount || fail
  fi

  # enable incus
  sudo usermod --append --groups incus-admin "${USER}" || fail
  sudo usermod -v 1000000-1000999999 -w 1000000-1000999999 root || fail
  sudo systemctl --now enable incus.service || fail
}
