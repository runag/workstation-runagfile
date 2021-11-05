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

if [[ "${OSTYPE}" =~ ^linux ]] && declare -f sopka-menu::add >/dev/null; then
  sopka-menu::add ubuntu-workstation::deploy-tailscale || fail
fi

ubuntu-workstation::deploy-tailscale() {
  # install gpg keys
  ubuntu-workstation::install-all-gpg-keys || fail

  # install bitwarden cli and login
  ubuntu-workstation::install-bitwarden-cli-and-login || fail

  if [ "${SOPKA_UPDATE_SECRETS:-}" = true ] || ! command -v tailscale >/dev/null || tailscale::is-logged-out; then
    bitwarden::unlock-and-sync || fail
    local tailscaleKey; tailscaleKey="$(bw get password "my tailscale reusable key")" || fail
    # shellcheck disable=2034
    local SOPKA_TASK_STDERR_FILTER=task::install-filter
    bitwarden::beyond-session task::run-with-short-title ubuntu-workstation::deploy-tailscale::stage-2 "${tailscaleKey}" || fail
  fi

  log::success "Done ubuntu-workstation::deploy-tailscale" || fail
}

ubuntu-workstation::deploy-tailscale::stage-2() {
  local tailscaleKey="$1"

  # install tailscale
  if ! command -v tailscale >/dev/null; then
    tailscale::install || fail
    if vmware::is-inside-vm; then
      tailscale::install-issue-2541-workaround || fail
    fi
  fi

  # logout if SOPKA_UPDATE_SECRETS is set
  if [ "${SOPKA_UPDATE_SECRETS:-}" = true ] && ! tailscale::is-logged-out; then
    sudo tailscale logout || fail
  fi

  # configure tailscale
  sudo tailscale up --authkey "${tailscaleKey}" || fail
}
