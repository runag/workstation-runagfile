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


sublime::install-config() {
  sublime::install-package-control || fail

  local selfDir; selfDir="$(dirname "${BASH_SOURCE[0]}")" || fail

  sublime::install-config-file "${selfDir}/Preferences.sublime-settings" || fail
  sublime::install-config-file "${selfDir}/Package Control.sublime-settings" || fail
  sublime::install-config-file "${selfDir}/Terminal.sublime-settings" || fail
}

sublime::install-license() {
  local configPath; configPath="$(sublime::get-config-path)" || fail

  dir::make-if-not-exists "${configPath}/Local" 755 || fail

  bitwarden::write-notes-to-file-if-not-exists "my sublime text 3 license" "${configPath}/Local/License.sublime_license" || fail
}

sublime::merge-config() {
  local selfDir; selfDir="$(dirname "${BASH_SOURCE[0]}")" || fail

  sublime::merge-config-file "${selfDir}/Preferences.sublime-settings" || fail
  sublime::merge-config-file "${selfDir}/Package Control.sublime-settings" || fail
  sublime::merge-config-file "${selfDir}/Terminal.sublime-settings" || fail
}
