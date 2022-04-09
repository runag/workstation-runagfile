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

if [[ "${OSTYPE}" =~ ^darwin ]] && declare -f sopka_menu::add >/dev/null; then
  sopka_menu::add macos-workstation::deploy || fail
  sopka_menu::add macos-workstation::configure || fail
fi

macos-workstation::deploy() {
  macos-workstation::install-basic-packages || fail
  macos-workstation::install-developer-packages || fail
  macos-workstation::configure || fail
  
  log::success "Done macos-workstation::deploy" || fail
}

macos-workstation::install-basic-packages() {
  # install homebrew
  macos::install_homebrew || fail

  # update and upgrade homebrew
  brew update || fail
  brew upgrade || fail

  # fan and battery
  brew install --cask macs-fan-control || fail
  brew install --cask coconutbattery || fail

  # productivity tools
  brew install --cask bitwarden || fail
  brew install --cask discord || fail
  brew install --cask grandperspective || fail
  brew install --cask libreoffice || fail
  brew install --cask skype || fail
  brew install --cask telegram || fail
  brew install --cask the-unarchiver || fail

  # chromium
  brew install --cask chromium || fail

  # media tools
  brew install --cask vlc || fail
  brew install --cask obs || fail
}

macos-workstation::install-developer-packages() {
  # basic tools
  brew install jq || fail
  brew install midnight-commander || fail
  brew install ranger || fail
  brew install ncdu || fail
  brew install htop || fail
  brew install p7zip || fail
  brew install sysbench || fail
  brew install hwloc || fail
  brew install tmux || fail

  # dev tools
  if [ ! -e /usr/local/bin/aws ]; then
    brew install awscli || fail
  fi

  brew install graphviz || fail
  brew install imagemagick || fail
  brew install ghostscript || fail
  brew install shellcheck || fail

  # memcached
  brew install memcached || fail
  brew services start memcached || fail

  # redis
  brew install redis || fail
  brew services start redis || fail

  # postgresql
  brew install postgresql || fail
  brew services start postgresql || fail

  # ffmpeg
  brew install ffmpeg || fail

  # meld
  brew install --cask meld || fail

  # sublime merge
  brew install --cask sublime-merge || fail

  # sublime text
  brew install --cask sublime-text || fail

  # vscode
  brew install --cask visual-studio-code || fail

  # iterm2
  brew install --cask iterm2 || fail

  # linode-cli
  pip3 install linode-cli --upgrade || fail

  # direnv
  brew install direnv || fail

  # gnupg
  brew install gnupg || fail

  # ruby
  brew install rbenv || fail

  # nodejs
  brew install nodenv || fail
  brew install yarn || fail

  # bitwarden-cli
  brew install bitwarden-cli || fail

  # sshfs
  # That will fail in CI test environment, so I disabled error checking here. Perhaps there is a better solution for that.
  brew install sshfs || true
}

macos-workstation::configure() {
  # increase maxfiles limits
  macos::increase_maxfiles_limit || fail

  # hide directories
  macos-workstation::hide-dirs || fail

  # shell aliases
  shellrc::install_loader "${HOME}/.bashrc" || fail
  shellrc::install_loader "${HOME}/.zshrc" || fail
  shellrc::install_editor_rc nano || fail
  shellrc::install_sopka_path_rc || fail
  shellrc::install_direnv_rc || fail

  # ruby
  ruby::dangerously_append_nodocument_to_gemrc || fail
  rbenv::install_shellrc || fail
  rbenv::load_shellrc || fail

  # nodejs
  nodenv::install_shellrc || fail
  nodenv::configure_mismatched_binaries_workaround || fail
  nodenv::load_shellrc || fail

  # vscode
  workstation::vscode::install-config || fail
  workstation::vscode::install_extensions || fail

  # sublime merge config
  workstation::sublime_merge::install-config || fail

  # sublime text config
  workstation::sublime_text::install-config || fail

  # secrets
  if [ -t 0 ]; then
    (
      # add ssh key, configure ssh to use it
      workstation::install-ssh-keys || fail
      ssh::macos_keychain::configure_use_on_all_hosts || fail
      bitwarden::use password "my password for ssh private key" ssh::macos_keychain || fail

      # rubygems
      workstation::install-rubygems-credentials || fail

      # npm
      workstation::install-npm-credentials || fail

      # sublime text license
      workstation::sublime_text::install-license || fail
    ) || fail
  fi

  # git
  workstation::configure-git || fail
  workstation::configure-git-user || fail

  log::success "Done macos-workstation::configure" || fail
}

macos-workstation::hide-dirs() {
  macos::hide_dir "${HOME}/Applications" || fail
  macos::hide_dir "${HOME}/Desktop" || fail
  macos::hide_dir "${HOME}/Documents" || fail
  macos::hide_dir "${HOME}/Movies" || fail
  macos::hide_dir "${HOME}/Music" || fail
  macos::hide_dir "${HOME}/Pictures" || fail
  macos::hide_dir "${HOME}/Public" || fail
  macos::hide_dir "${HOME}/Virtual Machines.localized" || fail
  macos::hide_dir "${HOME}/VirtualBox VMs" || fail
}
