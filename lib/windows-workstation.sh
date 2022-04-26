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

if [[ "${OSTYPE}" =~ ^msys ]] && declare -f sopka_menu::add >/dev/null; then
  sopka_menu::add windows_workstation::deploy_full_workstation || fail
  sopka_menu::add windows_workstation::deploy_base_workstation || fail
  sopka_menu::add windows_workstation::deploy_authentication || fail
fi


windows_workstation::deploy_full_workstation() {
  windows_workstation::deploy_base_workstation || fail

  # deploy authentication in a subshell
  ( windows_workstation::deploy_authentication ) || fail
}

windows_workstation::deploy_base_workstation() {
  # shell aliases
  shellrc::install_loader "${HOME}/.bashrc" || fail
  shellrc::install_editor_rc nano || fail
  shellrc::install_sopka_path_rc || fail

  # git
  workstation::configure_git || fail

  # vscode
  workstation::vscode::install_config || fail
  workstation::vscode::install_extensions || fail

  # sublime merge config
  workstation::sublime_merge::install_config || fail

  # sublime text config
  workstation::sublime_text::install_config || fail
}

windows_workstation::deploy_authentication() {
  # check dependencies
  command -v jq >/dev/null || fail "jq command is not found"
  command -v bw >/dev/null || fail "bw command is not found"

  # git user
  workstation::configure_git_user || fail

  # ssh key
  workstation::install_ssh_keys || fail

  # rubygems
  workstation::install_rubygems_credentials || fail

  # npm
  workstation::install_npm_credentials || fail

  # sublime text license
  workstation::sublime_text::install_license || fail
}
