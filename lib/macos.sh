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

macos::deploy-workstation() {
  macos::install-basic-packages || fail
  macos::install-developer-packages || fail
  macos::configure-workstation || fail

  touch "${HOME}/.sopka.workstation.deployed" || fail

  tools::perhaps-display-deploy-footnotes || fail
}

macos::install-basic-packages() {
  # install homebrew
  macos::install-homebrew || fail

  # update and upgrade homebrew
  brew update || fail
  brew upgrade || fail

  # fan and battery
  brew cask install macs-fan-control || fail
  brew cask install coconutbattery || fail

  # productivity tools
  brew cask install bitwarden || fail
  brew cask install discord || fail
  brew cask install grandperspective || fail
  brew cask install libreoffice || fail
  brew cask install skype || fail
  brew cask install telegram || fail
  brew cask install the-unarchiver || fail

  # chromium
  brew cask install chromium || fail

  # media tools
  brew cask install vlc || fail
  brew cask install obs || fail
}

macos::install-developer-packages() {
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
  brew install awscli || fail
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
  brew cask install meld || fail

  # sublime merge
  brew cask install sublime-merge || fail

  # sublime text
  brew cask install sublime-text || fail

  # vscode
  brew cask install visual-studio-code || fail

  # iterm2
  brew cask install iterm2 || fail

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
  brew install sshfs || fail
}

macos::configure-workstation() {
  # increase maxfiles limits
  macos::increase-maxfiles-limit || fail

  # hide folders
  macos::hide-folders || fail

  # shell aliases
  shellrcd::install || fail
  shellrcd::use-nano-editor || fail
  shellrcd::sopka-path || fail
  shellrcd::hook-direnv || fail
  bitwarden::shellrcd::set-bitwarden-login || fail

  # ruby
  ruby::configure-gemrc || fail
  shellrcd::rbenv || fail
  rbenv rehash || fail

  # nodejs
  shellrcd::nodenv || fail
  nodenv rehash || fail

  # vscode
  vscode::install-config || fail
  vscode::install-extensions "${SOPKAFILE_DIR}/lib/vscode/extensions.txt" || fail

  # sublime text
  sublime::install-config || fail

  # add ssh key, configure ssh to use it
  # bitwarden-object: "my ssh private key", "my ssh public key"
  ssh::install-keys "my" || fail
  ssh::macos::add-use-keychain-to-config || fail
  # bitwarden-object: "my password for ssh private key"
  ssh::macos::add-key-password-to-keychain "my" || fail

  # rubygems
  # bitwarden-object: "my rubygems credentials"
  bitwarden::write-notes-to-file-if-not-exists "my rubygems credentials" "${HOME}/.gem/credentials" || fail

  # git
  git::configure || fail
  git::configure-user || fail
}

macos::hide-folders() {
  macos::hide-folder "${HOME}/Applications" || fail
  macos::hide-folder "${HOME}/Desktop" || fail
  macos::hide-folder "${HOME}/Documents" || fail
  macos::hide-folder "${HOME}/Movies" || fail
  macos::hide-folder "${HOME}/Music" || fail
  macos::hide-folder "${HOME}/Pictures" || fail
  macos::hide-folder "${HOME}/Public" || fail
  macos::hide-folder "${HOME}/Virtual Machines.localized" || fail
  macos::hide-folder "${HOME}/VirtualBox VMs" || fail
}
