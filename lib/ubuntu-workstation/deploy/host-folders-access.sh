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

ubuntu_workstation::deploy-host-folders-access() {
  # install gpg keys
  ubuntu_workstation::install_gpg_keys || fail

  # install bitwarden cli and login
  ubuntu_workstation::install_bitwarden_cli_and_login || fail

  # mount host folder
  local credentials_file="${HOME}/.keys/host-filesystem-access.cifs-credentials"

  workstation::make_keys_directory_if_not_exists || fail
  bitwarden::use username password "my workstation virtual machine host filesystem access credentials" cifs::credentials "${credentials_file}" || fail

  # shellcheck disable=2034
  local SOPKA_TASK_STDERR_FILTER=task::install_filter
  bitwarden::beyond_session task::run_with_short_title ubuntu_workstation::deploy-host-folders-access::stage-2 "${credentials_file}" || fail

  log::success "Done ubuntu_workstation::deploy-host-folders-access" || fail
}

ubuntu_workstation::deploy-host-folders-access::stage-2() {
  local credentials_file="$1"

  local host_ip_address; host_ip_address="$(vmware::get_host_ip_address)" || fail

  apt::install cifs-utils || fail
  cifs::mount "//${host_ip_address}/my" "${HOME}/my" "${credentials_file}" || fail
  cifs::mount "//${host_ip_address}/ephemeral-data" "${HOME}/ephemeral-data" "${credentials_file}" || fail
}
