#!/usr/bin/env bash

#  Copyright 2012-2021 Stanislav Senotrusov <stan@senotrusov.com>
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

if declare -f sopka-menu::add >/dev/null; then
  sopka-menu::add windows-workstation::deploy || fail
fi

windows-workstation::deploy() {
  # check dependencies
  command -v bw >/dev/null || fail "bw command is not found"
  command -v jq >/dev/null || fail "jq command is not found"
  command -v code >/dev/null || fail "code command is not found"

  # shell aliases
  shell::install-shellrc-directory-loader "${HOME}/.bashrc" || fail
  shell::install-nano-editor-shellrc || fail
  shell::install-sopka-path-shellrc || fail

  # git
  workstation::configure-git || fail

  # vscode
  vscode::install-config || fail
  local selfDir; selfDir="$(dirname "${BASH_SOURCE[0]}")" || fail
  vscode::install-extensions "${selfDir}/vscode/extensions.txt" || fail

  # sublime text config
  sublime-text::install-config || fail

  # secrets
  if [ -t 0 ]; then
    (
      # add ssh key
      workstation::install-ssh-keys || fail

      # rubygems
      workstation::install-rubygems-credentials || fail

      # npm
      workstation::install-npm-credentials || fail

      # sublime text license
      sublime-text::install-license || fail
    ) || fail
  fi
}
