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
  sopka_menu::add_header Windows workstation || fail

  sopka_menu::add windows_workstation::deploy_workstation || fail
  sopka_menu::add windows_workstation::deploy_configuration || fail
  sopka_menu::add windows_workstation::deploy_secrets || fail

  sopka_menu::add_delimiter || fail
fi

windows_workstation::deploy_workstation() {
  windows_workstation::deploy_configuration || fail
  windows_workstation::deploy_secrets || fail
}

windows_workstation::deploy_configuration() {
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

windows_workstation::deploy_secrets() {(
  # Add MSYS2 path to access pass and tree that are installed via pacman
  # Maybe I should somehow add that path to my workstation globally, but I'm not sure what side effects it might bring
  export PATH="${PATH}:/c/tools/msys64/usr/bin"

  workstation::deploy_secrets || fail
)}
