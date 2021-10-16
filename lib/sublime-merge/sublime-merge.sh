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

workstation::sublime-merge::install-config() {
  local selfDir; selfDir="$(dirname "${BASH_SOURCE[0]}")" || fail

  sublime-merge::install-config-file "${selfDir}/Diff.sublime-settings" || fail
  sublime-merge::install-config-file "${selfDir}/Preferences.sublime-settings" || fail
}

workstation::sublime-merge::install-license() {
  local configPath; configPath="$(sublime-merge::get-config-path)" || fail

  dir::make-if-not-exists "${configPath}/Local" 700 || fail

  bitwarden::write-notes-to-file-if-not-exists "my sublime merge license" "${configPath}/Local/License.sublime_license" || fail
}

workstation::sublime-merge::merge-config() {
  local selfDir; selfDir="$(dirname "${BASH_SOURCE[0]}")" || fail

  sublime-merge::merge-config-file "${selfDir}/Diff.sublime-settings" || fail
  sublime-merge::merge-config-file "${selfDir}/Preferences.sublime-settings" || fail
}
