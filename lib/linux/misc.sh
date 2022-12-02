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

if runagfile_menu::necessary linux; then
  runagfile_menu::add_header "Linux workstation: misc" || fail
  
  runagfile_menu::add workstation::linux::dangerously_set_hostname || fail

  if linux::display_if_restart_required::is_available; then
    runagfile_menu::add workstation::linux::display_if_restart_required || fail
  fi

  if benchmark::is_available; then
    runagfile_menu::add workstation::linux::run_benchmark || fail
  fi
fi

workstation::linux::dangerously_set_hostname() {
  echo "Please keep in mind that the script to change hostname is not perfect, please take time to review the script and it's results"
  echo "Please enter new hostname:"
  
  local hostname; IFS="" read -r hostname || fail

  linux::dangerously_set_hostname "${hostname}" || fail
}

workstation::linux::display_if_restart_required() {
  linux::display_if_restart_required || fail
}

workstation::linux::run_benchmark() {
  benchmark::run || fail
}
