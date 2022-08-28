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
  sopka_menu::add windows_workstation::deploy_workstation_with_opionated_configuration || fail
  sopka_menu::add windows_workstation::deploy_workstation_without_secrets || fail

  sopka_menu::add_delimiter || fail

  sopka_menu::add windows_workstation::deploy_configuration || fail
  sopka_menu::add windows_workstation::deploy_opionated_configuration || fail
  sopka_menu::add windows_workstation::deploy_secrets || fail

  sopka_menu::add_delimiter || fail

  sopka_menu::add windows_workstation::configure_sopka_git_directories_as_safe || fail

  sopka_menu::add_delimiter || fail
fi

windows_workstation::deploy_workstation() {
  windows_workstation::deploy_workstation_without_secrets || fail
  windows_workstation::deploy_secrets || fail
}

windows_workstation::deploy_workstation_with_opionated_configuration() {
  windows_workstation::deploy_workstation || fail
  windows_workstation::deploy_opionated_configuration || fail
}

windows_workstation::deploy_workstation_without_secrets() {
  windows_workstation::deploy_software_packages || fail
  windows_workstation::deploy_configuration || fail
}

windows_workstation::deploy_software_packages() {
  # shellrc
  shellrc::install_loader "${HOME}/.bashrc" || fail
  shellrc::install_sopka_path_rc || fail
}

windows_workstation::deploy_configuration() {
  # configure git
  workstation::configure_git || fail
}

windows_workstation::deploy_opionated_configuration() {
  # set editor
  shellrc::install_editor_rc nano || fail

  # install vscode configuration
  workstation::vscode::install_extensions || fail
  workstation::vscode::install_config || fail

  # install sublime merge configuration
  workstation::sublime_merge::install_config || fail

  # install sublime text configuration
  workstation::sublime_text::install_config || fail
}

windows_workstation::deploy_secrets() {
  workstation::deploy_secrets || fail
}

windows_workstation::configure_sopka_git_directories_as_safe() {
  local user_profile; user_profile="$(<<<"${USERPROFILE}" tr '\\' '/')" || fail

  git config --global --add safe.directory "${user_profile}/.sopka/.git"
  git config --global --add safe.directory "${user_profile}/.sopka/sopkafiles/workstation-sopkafile-senotrusov-github/.git"
  git config --global --add safe.directory "${user_profile}/.sopka"
  git config --global --add safe.directory "${user_profile}/.sopka/sopkafiles/workstation-sopkafile-senotrusov-github"
}
