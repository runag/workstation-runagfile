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

workstation::windows::install_packages() {
  # shellrc
  shell::install_rc_loader || fail
  shell::install_rc_loader --file ".profile" --dir ".profile.d" || fail
  shell::set_runag_rc || fail
}

workstation::windows::configure() {
  # configure git
  workstation::configure_git || fail

  # set editor
  shell::set_editor_rc nano || fail

  # install vscode configuration
  workstation::vscode::install_extensions || fail
  workstation::vscode::install_config || fail

  # install sublime merge configuration
  workstation::sublime_merge::install_config || fail

  # install sublime text configuration
  # workstation::sublime_text::install_config || fail
}

# shellcheck disable=SC1003
workstation::windows::configure_runag_git_directories_as_safe() {
  local user_profile; user_profile="$(<<<"${USERPROFILE}" tr '\\' '/')" || fail

  git config --global --add safe.directory "${user_profile}/.runag/.git"
  git config --global --add safe.directory "${user_profile}/.runag/runagfiles/workstation-runagfile-runag-github/.git"
  git config --global --add safe.directory "${user_profile}/.runag"
  git config --global --add safe.directory "${user_profile}/.runag/runagfiles/workstation-runagfile-runag-github"
}
