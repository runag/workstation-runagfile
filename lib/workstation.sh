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

# Runagfiles
workstation::add_runagfiles() {
  local list_path="$1" # should be in the body

  pass::use --body "${list_path}" | runagfile::add_from_list
  test "${PIPESTATUS[*]}" = "0 0" || fail
}

# Git
workstation::configure_git() {
  local user_media_path; user_media_path="$(linux::user_media_path)" || fail

  git config --global core.autocrlf input || fail
  git config --global init.defaultBranch main || fail
  git config --global url."${user_media_path}/workstation-sync/".insteadOf "/workstation-sync/" || fail
}

# Cleanup
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

# Config
workstation::get_config_dir() {
  local config_home="${XDG_CONFIG_HOME:-"${HOME}/.config"}"
  dir::should_exists --mode 0700 "${config_home}" || fail

  local config_dir="${config_home}/workstation-runagfile"
  dir::should_exists --mode 0700 "${config_dir}" || fail

  if [ -n "${1:-}" ]; then
    config_dir="${config_dir}/$1"
    dir::should_exists --mode 0700 "${config_dir}" || fail
  fi
  
  echo "${config_dir}"
}

# Micro editor
workstation::install_micro_config() {
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

# Editor configs
workstation::merge_editor_configs() {
  workstation::vscode::merge_config || fail
  workstation::sublime_merge::merge_config || fail
  workstation::sublime_text::merge_config || fail
}
