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
  sopka_menu::add_header "macOS workstation" || fail
  
  sopka_menu::add macos_workstation::deploy_workstation || fail
  sopka_menu::add macos_workstation::deploy_workstation_without_secrets || fail
  sopka_menu::add macos_workstation::deploy_software_packages || fail
  sopka_menu::add macos_workstation::deploy_configuration || fail
  sopka_menu::add macos_workstation::deploy_secrets || fail
  sopka_menu::add macos_workstation::deploy_opionated_configuration || fail
  sopka_menu::add macos_workstation::start_developer_servers || fail

  sopka_menu::add_delimiter || fail
fi

macos_workstation::deploy_workstation() {
  macos_workstation::deploy_workstation_without_secrets || fail
  macos_workstation::deploy_secrets || fail
}

macos_workstation::deploy_workstation_without_secrets() {
  macos_workstation::deploy_software_packages || fail
  macos_workstation::deploy_configuration || fail
}

macos_workstation::deploy_software_packages() {
  # install homebrew
  macos::install_homebrew || fail

  # update and upgrade homebrew
  brew update || fail
  brew upgrade || fail

  # install packages
  macos_workstation::install_basic_tools || fail
  macos_workstation::install_developer_tools || fail
}

macos_workstation::install_basic_tools() {
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

macos_workstation::install_developer_tools() {
  # secrets
  brew install gnupg || fail

  # servers
  brew install memcached || fail
  brew install postgresql || fail
  brew install redis || fail

  # gui tools
  brew install --cask meld || fail
  brew install --cask sublime-merge || fail
  brew install --cask sublime-text || fail
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

macos_workstation::deploy_configuration() {
  # shell aliases
  shellrc::install_loader "${HOME}/.bashrc" || fail
  shellrc::install_loader "${HOME}/.zshrc" || fail
  shellrc::install_editor_rc nano || fail
  shellrc::install_sopka_path_rc || fail
  shellrc::install_direnv_rc || fail

  # git
  workstation::configure_git || fail

  # vscode
  workstation::vscode::install_config || fail
  workstation::vscode::install_extensions || fail

  # sublime merge config
  workstation::sublime_merge::install_config || fail

  # sublime text config
  workstation::sublime_text::install_config || fail

  # configure ssh client
  ssh::macos_keychain::configure_use_on_all_hosts || fail

  # increase maxfiles limits
  macos::increase_maxfiles_limit || fail

  # ruby
  rbenv::install_shellrc || fail
  ruby::dangerously_append_nodocument_to_gemrc || fail

  # nodejs
  nodenv::install_shellrc || fail
  nodenv::configure_mismatched_binaries_workaround || fail
}

macos_workstation::deploy_secrets() {
  # ssh key
  workstation::install_ssh_keys || fail
  bitwarden::use password "${MY_SSH_KEY_PASSWORD_ID}" ssh::macos_keychain || fail

  # git
  workstation::configure_git_user || fail

  # rubygems
  workstation::install_rubygems_credentials || fail

  # npm
  workstation::install_npm_credentials || fail

  # sublime text license
  workstation::sublime_text::install_license || fail
}

macos_workstation::deploy_opionated_configuration() {
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

macos_workstation::start_developer_servers() {
  brew services start memcached || fail
  brew services start redis || fail
  brew services start postgresql || fail
}
