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

workstation::linux::set_hostname() {
  echo "Please keep in mind that the script to change hostname is not perfect, please take time to review the script and it's results"
  echo "Please enter new hostname:"
  
  local hostname; IFS="" read -r hostname || fail

  linux::set_hostname "${hostname}" || fail
}

workstation::linux::run_benchmark() {
  benchmark::run || fail
}

workstation::linux::write_system_config() {
  local config_path="$1"

  local config_directory="/var/lib/workstation-runagfile"
  dir::should_exists --sudo --mode 0700 "${config_directory}" || fail

  file::write --sudo --mode 0600 "${config_directory}/${config_path}" || fail
}
