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

workstation::vscode::user_config_path() {
  local config_home; config_home="$(cross_platform::config_home)" || fail

  local short_name="Code"

  dir::should_exists --mode 0700 "${config_home}" || fail
  dir::should_exists --mode 0700 "${config_home}/${short_name}" || fail
  dir::should_exists --mode 0700 "${config_home}/${short_name}/User" || fail

   echo "${config_home}/${short_name}/User"
}

workstation::vscode::install_extensions() (
  shell::related_cd || fail
  vscode::install_extensions "extensions.txt" || fail
)

workstation::vscode::install_config() (
  shell::related_cd || fail

  local user_config_path; user_config_path="$(workstation::vscode::user_config_path)" || fail

  config::install "settings.json" "${user_config_path}/settings.json" || fail
  config::install "keybindings.json" "${user_config_path}/keybindings.json" || fail
)

workstation::vscode::merge_config() (
  shell::related_cd || fail

  local user_config_path; user_config_path="$(workstation::vscode::user_config_path)" || fail

  config::merge "settings.json" "${user_config_path}/settings.json" || fail
  config::merge "keybindings.json" "${user_config_path}/keybindings.json" || fail

  local extensions_list; extensions_list="$(vscode::list_extensions_to_temp_file)" || fail "Unable get extensions list"
  config::merge "extensions.txt" "${extensions_list}" || fail
  rm "${extensions_list}" || fail
)
