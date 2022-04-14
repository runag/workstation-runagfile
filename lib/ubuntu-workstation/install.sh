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

ubuntu_workstation::install-system-software() {
  # install open-vm-tools
  if vmware::is_inside_vm; then
    apt::install open-vm-tools || fail
  fi

  # install cloud guest utils
  apt::install cloud-guest-utils || fail

  # install inotify tools
  apt::install inotify-tools || fail
}

ubuntu_workstation::install-terminal-software() {
  apt::install \
    apache2-utils \
    awscli \
    certbot \
    direnv \
    ffmpeg \
    git \
    gnupg \
    graphviz \
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
}

ubuntu_workstation::install-build-tools() {
  apt::install \
    build-essential \
    libsqlite3-dev \
    libssl-dev \
      || fail
}

ubuntu_workstation::install-servers() {
  apt::install memcached || fail
  apt::install postgresql postgresql-contrib libpq-dev || fail
  apt::install redis-server || fail
}

ubuntu_workstation::install-and-update-nodejs() {
  nodejs::install_by_nodenv_and_set_global "16.13.0" || fail
}

ubuntu_workstation::install-and-update-ruby() {
  ruby::dangerously_append_nodocument_to_gemrc || fail
  RUBY_CONFIGURE_OPTS="--disable-install-doc" ruby::install_and_set_global_by_rbenv "3.0.2" || fail

  shellrc::write "disable-spring" <<< "export DISABLE_SPRING=true" || fail
}

ubuntu_workstation::install-and-update-python() {
  python::install_and_update::apt || fail
}

ubuntu_workstation::install-desktop-software::apt() {
  # open-vm-tools-desktop
  if vmware::is_inside_vm; then
    apt::install open-vm-tools-desktop || fail
  fi

  # install dconf-editor
  apt::install dconf-editor || fail

  # sublime text and sublime merge
  sublime_merge::install::apt || fail
  sublime_text::install::apt || fail

  # meld
  apt::install meld || fail

  # gparted
  apt::install gparted || fail

  # GNU Privacy Assistant
  apt::install gpa || fail

  # imwheel
  if [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then
    apt::install imwheel || fail
  fi

  # software for bare metal workstation
  if linux::is_bare_metal; then
    # copyq
    ubuntu_workstation::install-copyq || fail

    # hardware monitoring
    apt::install ddccontrol gddccontrol ddccontrol-db i2c-tools || fail
    ubuntu_workstation::install-vitals || fail

    # OBS studio
    ubuntu_workstation::install-obs-studio || fail
  fi
}

ubuntu_workstation::install-desktop-software::snap() {
  # vscode
  vscode::install::snap || fail
  workstation::vscode::install_extensions || fail

  # micro
  sudo snap install micro --classic || fail
  shellrc::install_editor_rc micro || fail

  # chromium
  sudo snap install chromium || fail

  # bitwarden
  sudo snap install bitwarden || fail

  # software for bare metal workstation
  if linux::is_bare_metal; then
    # skype
    sudo snap install skype --classic || fail

    # telegram desktop
    sudo snap install telegram-desktop || fail

    # discord
    sudo snap install discord || fail
  fi
}

ubuntu_workstation::install-vitals() {
  apt::install gnome-shell-extensions gir1.2-gtop-2.0 lm-sensors || fail

  local extension_uuid="Vitals@CoreCoding.com"
  local extensions_dir="${HOME}/.local/share/gnome-shell/extensions"

  dir::make_if_not_exists "${HOME}/.local" 755 || fail
  dir::make_if_not_exists "${HOME}/.local/share" 755 || fail
  dir::make_if_not_exists "${HOME}/.local/share/gnome-shell" 700 || fail
  dir::make_if_not_exists "${extensions_dir}" 700 || fail

  git::place_up_to_date_clone "https://github.com/corecoding/Vitals" "${extensions_dir}/${extension_uuid}" || fail

  gnome-extensions enable "${extension_uuid}" || fail
}

ubuntu_workstation::install-copyq() {
  sudo add-apt-repository --yes ppa:hluk/copyq || fail
  apt::update || fail
  apt::install copyq || fail
}

ubuntu_workstation::install-obs-studio() {
  sudo add-apt-repository --yes ppa:obsproject/obs-studio || fail
  apt::update || fail
  apt::install obs-studio guvcview || fail
}

ubuntu_workstation::install-shellrc() {
  shellrc::install_loader "${HOME}/.bashrc" || fail
  shellrc::install_sopka_path_rc || fail
}

ubuntu_workstation::install-all-gpg-keys() {
  ubuntu_workstation::install-gpg-key "84C200370DF103F0ADF5028FF4D70B8640424BEA" || fail
}

ubuntu_workstation::install-gpg-key() {
  local key="$1"
  gpg::import_key_with_ultimate_ownertrust "${key}" "/media/${USER}/KEYS-DAILY/keys/gpg/${key:(-8)}/${key:(-8)}-secret-subkeys.asc" || fail
}

ubuntu_workstation::install-bitwarden-cli-and-login() {
  bitwarden::install_cli::snap || fail

  if ! bitwarden::is_logged_in; then
    gpg::decrypt_and_source_script "/media/${USER}/KEYS-DAILY/keys/bitwarden/stan-api-key.sh.asc" || fail
    bitwarden::login --apikey || fail
  fi
}
