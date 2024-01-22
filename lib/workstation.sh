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

workstation::configure_git() {
  git config --global core.autocrlf input || fail
  git config --global init.defaultBranch main || fail
}

workstation::merge_editor_configs() {
  workstation::vscode::merge_config || fail
  workstation::sublime_merge::merge_config || fail
  # workstation::sublime_text::merge_config || fail
}

workstation::remove_nodejs_and_ruby_installations() {
  if asdf plugin list | grep -qFx nodejs; then
    asdf uninstall nodejs || fail
  fi

  if asdf plugin list | grep -qFx ruby; then
    asdf uninstall ruby || fail
  fi

  rm -rf "${HOME}/.nodenv/versions"/* || fail
  rm -rf "${HOME}/.rbenv/versions"/* || fail

  rm -rf "${HOME}/.cache/yarn" || fail
  rm -rf "${HOME}/.solargraph" || fail
  rm -rf "${HOME}/.bundle" || fail
  rm -rf "${HOME}/.node-gyp" || fail
}

workstation::add_runagfiles() {
  local list_path="$1" # should be in the body

  pass::use --body "${list_path}" | runagfile::add_from_list
  test "${PIPESTATUS[*]}" = "0 0" || fail
}

workstation::get_flag() {
  local flag_name="$1"
  local flag_directory="${HOME}/.workstation-runagfile-config"
  test -f "${flag_directory}/${flag_name}.flag"
}

workstation::set_flag() {
  local flag_name="$1"
  local flag_directory="${HOME}/.workstation-runagfile-config"
  dir::should_exists --mode 0700 "${flag_directory}" || fail
  touch "${flag_directory}/${flag_name}.flag" || fail
}

workstation::write_config() {
  local config_path="$1"

  local config_directory="${HOME}/.workstation-runagfile-config"
  dir::should_exists --mode 0700 "${config_directory}" || fail

  file::write --mode 0600 "${config_directory}/${config_path}" || fail
}

workstation::write_micro_config() {
  local config_dir="${HOME}/.config/micro"

  dir::should_exists --mode 0700 "${config_dir}" || fail

  file::write --mode 640 "${config_dir}/settings.json" <<JSON || softfail || return $?
{
  "autoclose": false
}
JSON

  file::write --mode 640 "${config_dir}/bindings.json" <<JSON || softfail || return $?
{
  "Ctrl-x": "Quit"
}
JSON
}
