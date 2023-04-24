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

workstation::misc::runagfile_menu() {

  runagfile_menu::add --header "Git" || fail

  if [ -d .git ]; then
    runagfile_menu::add git::disable_nested_repositories || fail
    runagfile_menu::add git::enable_nested_repositories || fail
  else
    runagfile_menu::add --note "Not in a git folder" || fail
  fi


  if runagfile_menu::necessary --os linux; then

    runagfile_menu::add --header "Storage" || fail

    runagfile_menu::add workstation::linux::storage::check_root || fail


    runagfile_menu::add --header "Benchmark" || fail

    if benchmark::is_available; then
      runagfile_menu::add workstation::linux::run_benchmark || fail
    else
      runagfile_menu::add --note "Benchmark is not available" || fail
    fi
  fi
}
