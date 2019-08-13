#!/usr/bin/env bash

#  Copyright 2012-2016 Stanislav Senotrusov <stan@senotrusov.com>
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

fail() {
  echo "${BASH_SOURCE[1]}:${BASH_LINENO[0]}: in \`${FUNCNAME[1]}': Error: ${1:-"Abnormal termination"}" >&2
  exit "${2:-1}"
}

tools::sudo-write-file() {
  local dest="$1"
  local mode="${2:-0644}"
  local owner="${3:-root}"
  local group="${4:-$owner}"

  local dirName; dirName="$(dirname "${dest}")" || { echo "Unable to get dirName of '${dest}' (${?})" >&2; exit 1; }

  sudo mkdir -p "${dirName}" || { echo "Unable to mkdir -p '${dirName}' (${?})" >&2; exit 1; }

  cat | sudo tee "$dest"
  test "${PIPESTATUS[*]}" = "0 0" || { echo "Unable to cat or write to dest $dest" >&2; exit 1; }

  sudo chmod "$mode" "$dest" || { echo "Unable to chmod '${dest}' (${?})" >&2; exit 1; }
  sudo chown "$owner:$group" "$dest" || { echo "Unable to chown '${dest}' (${?})" >&2; exit 1; }
}
