#!/usr/bin/env bash

#  Copyright 2012-2019 Stanislav Senotrusov <stan@senotrusov.com>
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

tasks::select() {
  local actionList=(
    deploy::data-pi
    deploy::macos-non-developer-workstation
    deploy::macos-workstation
    deploy::ubuntu-workstation
    deploy::merge-workstation-configs
    backup::polina-archive
    backup::stan-archive
    benchmark
  )

  echo "Please choose an action to perform:"
  for i in ${!actionList[@]}; do
    echo "  ${i}: ${actionList[$i]}"
  done

  local action
  IFS="" read -r action || fail

  if [ -n "${action:-}" ]; then
    local actionFunction="${actionList[$action]}"
    declare -f "${actionFunction}" >/dev/null || fail "Argument must be a function name: $1"
    "${actionFunction}" || fail
  fi
}
