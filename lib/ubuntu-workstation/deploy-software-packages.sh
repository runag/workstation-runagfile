#!/usr/bin/env bash

#  Copyright 2012-2022 Stanislav Senotrusov <stan@senotrusov.com>
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

ubuntu_workstation::deploy_software_packages() {
  # perform autoremove, update and upgrade
  apt::autoremove_lazy_update_and_maybe_dist_upgrade || fail

  # install tools to use by the rest of the script
  apt::install_sopka_essential_dependencies || fail

  # install display-if-restart-required dependencies
  apt::install_display_if_restart_required_dependencies || fail

  # install gnome-keyring and libsecret (for git and ssh)
  apt::install_gnome_keyring_and_libsecret || fail
  git::install_libsecret_credential_helper || fail

  # install benchmark
  benchmark::install::apt || fail

  # shellrc
  shellrc::install_loader "${HOME}/.bashrc" || fail
  shellrc::install_sopka_path_rc || fail
  shellrc::install_direnv_rc || fail

  # install open-vm-tools
  if vmware::is_inside_vm; then
    apt::install open-vm-tools open-vm-tools-desktop || fail
  fi

  # install inotify tools
  apt::install inotify-tools || fail

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
    xclip \
    zsh \
      || fail

  # gparted dependencies for FAT partitions
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

  # nodejs
  asdf::install_dependencies_by_apt || fail
  asdf::install_with_shellrc || fail

  nodejs::install_asdf_specific_dependencies_by_apt || fail
  nodejs::install_by_asdf_and_set_global || fail

  # ruby
  ruby::dangerously_append_nodocument_to_gemrc || fail
  shellrc::write "disable-spring" <<< "export DISABLE_SPRING=true" || fail
  RUBY_CONFIGURE_OPTS="--disable-install-doc" ruby::install_and_set_global_by_rbenv || fail

  # python
  python::install_and_update::apt || fail

  # file-digests
  gem install file-digests || fail


  ### desktop software

  # vscode
  vscode::install::snap || fail

  # sublime text and sublime merge
  sublime_merge::install::apt || fail
  sublime_text::install::apt || fail

  # micro text editor
  sudo snap install micro --classic || fail

  # meld
  apt::install meld || fail

  # chromium
  sudo snap install chromium || fail

  # bitwarden
  sudo snap install bitwarden || fail
  sudo snap connect bitwarden:password-manager-service || fail

  # qtpass
  apt::install qtpass || fail

  # gparted
  apt::install gparted || fail

  # GNU Privacy Assistant
  apt::install gpa || fail

  # install dconf-editor
  apt::install dconf-editor || fail

  # imwheel
  apt::install imwheel || fail

  # software for bare metal workstation
  if linux::is_bare_metal; then
    # nvme-cli
    sudo apt-get install nvme-cli || fail
    
    # skype
    sudo snap install skype --classic || fail

    # telegram desktop
    sudo snap install telegram-desktop || fail

    # discord
    sudo snap install discord || fail
    sudo snap connect discord:system-observe || fail

    # spotify
    sudo snap install spotify || fail

    # inkscape
    sudo snap install inkscape || fail

    # krita
    sudo snap install krita || fail

    # OBS studio
    sudo add-apt-repository --yes ppa:obsproject/obs-studio || fail
    apt::update || fail
    apt::install obs-studio guvcview || fail

    # copyq
    sudo add-apt-repository --yes ppa:hluk/copyq || fail
    apt::update || fail
    apt::install copyq || fail

    # monitor control
    apt::install ddccontrol gddccontrol ddccontrol-db i2c-tools || fail

    # My MSI laptop hardware control
    if grep -qFx "GF65 Thin 9SD" /sys/devices/virtual/dmi/id/product_name && \
       grep -qFx "Micro-Star International Co., Ltd." /sys/devices/virtual/dmi/id/board_vendor; then
      git::place_up_to_date_clone "https://github.com/senotrusov/msi-ec" "${HOME}/.msi-ec" || fail
      apt::install linux-headers-generic || fail
      ( cd "${HOME}/.msi-ec" && make && sudo make install ) || fail
    fi
  fi
}
