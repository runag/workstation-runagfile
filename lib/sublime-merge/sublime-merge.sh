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

workstation::sublime_merge::install_config() {
  local self_dir; self_dir="$(dirname "${BASH_SOURCE[0]}")" || fail

  sublime_merge::install_config_file "${self_dir}/Diff.sublime-settings" || fail
  sublime_merge::install_config_file "${self_dir}/Preferences.sublime-settings" || fail
}

workstation::sublime_merge::install_license() {
  local license_path="$1" # should be in the body

  local config_path; config_path="$(sublime_merge::get_config_path)" || fail

  dir::should_exists --mode 0700 "${config_path}/Local" || fail

  pass::use --absorb-in-callback --body "${license_path}" file::write --mode 0600 "${config_path}/Local/License.sublime_license" || fail
}

workstation::sublime_merge::merge_config() {
  local self_dir; self_dir="$(dirname "${BASH_SOURCE[0]}")" || fail

  sublime_merge::merge_config_file "${self_dir}/Diff.sublime-settings" || fail
  sublime_merge::merge_config_file "${self_dir}/Preferences.sublime-settings" || fail
}
