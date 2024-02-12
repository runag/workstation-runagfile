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

workstation::macos::install_packages() {
  # install homebrew
  macos::install_homebrew || fail

  # update and upgrade homebrew
  brew update || fail
  brew upgrade || fail

  # fan and battery
  brew install --cask macs-fan-control || fail
  brew install --cask coconutbattery || fail

  # productivity tools
  brew install --cask discord || fail
  brew install --cask grandperspective || fail
  brew install --cask libreoffice || fail
  brew install --cask skype || fail
  brew install --cask the-unarchiver || fail

  # chromium
  brew install --cask chromium || fail

  # media tools
  brew install --cask vlc || fail
  brew install --cask obs || fail

  # secrets
  brew install gnupg || fail

  # servers
  brew install memcached || fail
  brew install postgresql || fail
  brew install redis || fail

  # gui tools
  brew install --cask meld || fail
  brew install --cask sublime-merge || fail
  # brew install --cask sublime-text || fail
  brew install --cask visual-studio-code || fail
  brew install --cask iterm2 || fail

  # basic tools
  brew install direnv || fail
  brew install htop || fail
  brew install jq || fail
  brew install midnight-commander || fail
  brew install ncdu || fail
  brew install p7zip || fail
  brew install sysbench || fail
  brew install tmux || fail

  # specialized console tools
  if [ "${CI:-}" = "true" ] && [ -e /usr/local/bin/aws ]; then # Check if CI image already contains aws
    echo "CI image already contains aws"
  else
    brew install awscli || fail
  fi

  brew install ffmpeg || fail
  brew install ghostscript || fail
  brew install graphviz || fail
  brew install imagemagick || fail
  brew install shellcheck || fail

  # ruby
  brew install rbenv || fail

  # nodejs
  brew install nodenv || fail
  brew install yarn || fail
}

workstation::macos::configure() {
  # shellrc
  shell::install_rc_loader || fail
  shell::install_rc_loader --file ".bashrc" || fail
  shell::install_rc_loader --file ".profile" --dir ".profile.d" || fail
  shell::set_runag_rc || fail
  shell::set_direnv_rc || fail
  shell::set_editor_rc nano || fail

  # git
  workstation::configure_git || fail

  # configure ssh client
  ssh::macos_keychain::configure_use_on_all_hosts || fail

  # increase maxfiles limits
  macos::increase_maxfiles_limit || fail

  # ruby
  ruby::dangerously_append_nodocument_to_gemrc || fail

  # vscode
  workstation::vscode::install_extensions || fail
  workstation::vscode::install_config || fail

  # sublime merge config
  workstation::sublime_merge::install_config || fail

  # sublime text config
  # workstation::sublime_text::install_config || fail

  # hide directories
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

workstation::macos::start_developer_servers() {
  brew services start memcached || fail
  brew services start redis || fail
  brew services start postgresql || fail
}
