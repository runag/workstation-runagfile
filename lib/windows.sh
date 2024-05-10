#!/usr/bin/env bash

#  Copyright 2012-2024 Rùnag project contributors
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

# shellcheck disable=SC1003
workstation::windows::configure() {
  # shellfiles
  shellfile::install_loader::bash || fail
  shellfile::install_runag_path_profile || fail
  shellfile::install_editor_rc nano || fail

  # configure git
  workstation::configure_git || fail

  # install vscode configuration
  workstation::vscode::install_extensions || fail
  workstation::vscode::install_config || fail

  # install sublime merge configuration
  workstation::sublime_merge::install_config || fail

  # install sublime text configuration
  # workstation::sublime_text::install_config || fail

  # mark runag git directories as safe
  local profile_dir; profile_dir="$(<<<"${USERPROFILE}" tr '\\' '/')" || fail

  git config --global --add safe.directory "${profile_dir}/.runag/.git"
  git config --global --add safe.directory "${profile_dir}/.runag/runagfiles/workstation-runagfile-runag-github/.git"
  git config --global --add safe.directory "${profile_dir}/.runag"
  git config --global --add safe.directory "${profile_dir}/.runag/runagfiles/workstation-runagfile-runag-github"
}
