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

workstation::linux::deploy_tailscale() {
  local key_path="$1" # sould be in the password

  # install tailscale
  if ! command -v tailscale >/dev/null; then
    tailscale::install || fail
  fi

  if vmware::is_inside_vm; then
    # https://github.com/tailscale/tailscale/issues/2541
    tailscale::install_issue_2541_workaround || fail
  fi

  if ! tailscale::is_logged_in; then
    local tailscale_key; tailscale_key="$(pass::use "${key_path}")" || fail
    sudo tailscale up --authkey "${tailscale_key}" || fail  
  fi
}
