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

workstation::linux::deploy_host_folder_mounts() {
  # install cifs-utils
  apt::install cifs-utils || fail

  # get user name
  local username; username="$(pass::use "${MY_WINDOWS_CIFS_CREDENTIALS_PATH}" --get username)" || fail

  # write credentials to local filesystem
  local credentials_file="${MY_KEYS_PATH}/host-filesystem-access.cifs-credentials"

  workstation::make_keys_directory_if_not_exists || fail
  
  pass::use "${MY_WINDOWS_CIFS_CREDENTIALS_PATH}" cifs::credentials "${credentials_file}" "${username}" || fail

  # get host ip address
  local remote_host; remote_host="$(vmware::get_host_ip_address)" || fail

  # mount host folder
  REMOTE_HOST="${remote_host}" CREDENTIALS_FILE="${credentials_file}" workstation::linux::mount_host_folders || fail
}

workstation::linux::mount_host_folders() {
  workstation::linux::mount_host_folder "my" || fail
}

# shellcheck disable=2153
workstation::linux::mount_host_folder() {
  cifs::mount "//${REMOTE_HOST}/$1" "${HOME}/${2:-"$1"}" "${CREDENTIALS_FILE}" || fail
}
