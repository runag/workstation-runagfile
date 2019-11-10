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

homebrew::install-homebrew() {
  if ! command -v brew >/dev/null; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null || fail "Unable to install homebrew"
  fi
}

macos::install-basic-packages() {
  # install homebrew
  homebrew::install-homebrew || fail

  # update and upgrade homebrew
  brew update || fail
  brew upgrade || fail

  # fan and battery
  brew cask install macs-fan-control || fail
  brew cask install coconutbattery || fail

  # syncthing
  brew install syncthing || fail
  brew services start syncthing || fail

  # productivity tools
  brew cask install bitwarden || fail
  brew cask install discord || fail
  brew cask install libreoffice || fail
  brew cask install skype || fail
  brew cask install telegram || fail
  brew cask install the-unarchiver || fail

  # chromium
  brew cask install chromium || fail

  # obs studio
  brew cask install obs || fail
}

macos::install-developer-packages() {
  # bitwarden-cli
  brew install bitwarden-cli || fail

  # basic tools
  brew install jq || fail
  brew install midnight-commander || fail
  brew install ranger || fail
  brew install ncdu || fail
  brew install htop || fail
  brew install p7zip || fail
  brew install sysbench || fail
  brew install hwloc || fail

  # dev tools
  brew install awscli || fail
  brew install graphviz || fail
  brew install imagemagick || fail
  brew install ghostscript || fail
  brew install shellcheck || fail

  # servers
  brew install memcached || fail
  brew install redis || fail
  brew install postgresql || fail

  # tor
  brew install tor || fail

  # ffmpeg
  brew install ffmpeg || fail

  # nodejs and jarn
  brew install node || fail
  brew install yarn || fail

  # meld
  brew cask install meld || fail

  # sublime merge
  brew cask install sublime-merge || fail

  # sublime text 
  brew cask install sublime-text || fail
  
  # vscode
  brew cask install visual-studio-code || fail
}
