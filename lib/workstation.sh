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
  local full_path="${XDG_CONFIG_HOME:-"${HOME}/.config"}/workstation-runagfile${1:+"/$1"}"

  dir::should_exists --for-me-only "${full_path}" || fail

  echo "${full_path}"
}

# Editor configs
workstation::merge_editor_configs() {
  workstation::micro::merge_config || fail
  workstation::sublime_merge::merge_config || fail
  workstation::sublime_text::merge_config || fail
  workstation::vscode::merge_config || fail
}

# Connect to tailscale
workstation::connect_tailscale() {
  local key_path="$1" # key sould be in the password

  if ! tailscale::is_logged_in; then
    pass::use "${key_path}" sudo tailscale up --authkey || fail  
  fi
}
