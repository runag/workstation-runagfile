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
  if vmware::is-inside-vm; then
    sopka-menu::add-header Deploy || fail
    sopka-menu::add ubuntu-workstation::deploy-host-folders-access || fail
  fi
fi

ubuntu-workstation::deploy-host-folders-access() {
  # install gpg keys
  ubuntu-workstation::install-all-gpg-keys || fail

  # install bitwarden cli and login
  ubuntu-workstation::install-bitwarden-cli-and-login || fail

  # mount host folder
  local credentialsFile="${HOME}/.keys/host-filesystem-access.cifs-credentials"

  workstation::make-keys-directory-if-not-exists || fail
  bitwarden::use username password "my workstation virtual machine host filesystem access credentials" cifs::credentials "${credentialsFile}" || fail

  # shellcheck disable=2034
  local SOPKA_TASK_STDERR_FILTER=task::install-filter
  bitwarden::beyond-session task::run-with-short-title ubuntu-workstation::deploy-host-folders-access::stage-2 "${credentialsFile}" || fail

  log::success "Done ubuntu-workstation::deploy-host-folders-access" || fail
}

ubuntu-workstation::deploy-host-folders-access::stage-2() {
  local credentialsFile="$1"

  local hostIpAddress; hostIpAddress="$(vmware::get-host-ip-address)" || fail

  apt::install cifs-utils || fail
  cifs::mount "//${hostIpAddress}/my" "${HOME}/my" "${credentialsFile}" || fail
  cifs::mount "//${hostIpAddress}/ephemeral-data" "${HOME}/ephemeral-data" "${credentialsFile}" || fail
}
