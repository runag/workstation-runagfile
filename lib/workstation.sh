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

if sopkafile_menu::necessary; then
  sopkafile_menu::add_header "Workstation: misc" || fail
  
  sopkafile_menu::add workstation::add_sopkafiles deployment-repository/personal || fail
  sopkafile_menu::add workstation::sublime_merge::install_license sublime-merge/personal || fail
  sopkafile_menu::add workstation::sublime_text::install_license sublime-text/personal || fail
  sopkafile_menu::add workstation::merge_editor_configs || fail
  sopkafile_menu::add workstation::remove_nodejs_and_ruby_installations || fail
fi

workstation::configure_git() {
  git config --global core.autocrlf input || fail
  git config --global init.defaultBranch main || fail
}

workstation::merge_editor_configs() {
  workstation::vscode::merge_config || fail
  workstation::sublime_merge::merge_config || fail
  workstation::sublime_text::merge_config || fail
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

workstation::add_sopkafiles() {
  local list_path="$1" # should be in the body

  pass::use --body "${list_path}" | sopkafile::add_from_list
  test "${PIPESTATUS[*]}" = "0 0" || fail
}
