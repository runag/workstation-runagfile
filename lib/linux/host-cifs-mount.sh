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

workstation::linux::deploy_host_cifs_mount() {
  local credentials_path="$1" # username, password
  local remote_path="$2"
  local local_path="${3:-"${remote_path}"}"

  local credentials_file; credentials_file="$(workstation::get_config_path "host-cifs-credentials")" || fail

  # install cifs-utils
  apt::install cifs-utils || fail

  # get user name
  local username; username="$(pass::use --get username "${credentials_path}")" || fail

  # write credentials to local filesystem
  pass::use "${credentials_path}" cifs::credentials "${credentials_file}" "${username}" || fail

  # get host ip address
  local remote_host; remote_host="$(vmware::get_host_ip_address)" || fail

  # mount host directory
  cifs::mount "//${remote_host}/${remote_path}" "${HOME}/${local_path}" "${credentials_file}" || fail
}
