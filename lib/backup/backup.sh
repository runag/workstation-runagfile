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

# shellcheck disable=2030
workstation::backup() {(
  export WORKSTATION_BACKUP_PROFILE="workstation"
  export WORKSTATION_BACKUP_PASSWORD="default"
  export WORKSTATION_BACKUP_REPOSITORY="default"

  while [[ "$#" -gt 0 ]]; do
    case $1 in
    -p|--profile)
      WORKSTATION_BACKUP_PROFILE="$2"
      shift; shift
      ;;
    -w|--password)
      WORKSTATION_BACKUP_PASSWORD="$2"
      shift; shift
      ;;
    -r|--repository)
      WORKSTATION_BACKUP_REPOSITORY="$2"
      shift; shift
      ;;
    -*)
      softfail "Unknown argument: $1" || return $?
      ;;
    *)
      break
      ;;
    esac
  done

  local action_name="$1"; shift

  local config_dir="${HOME}/.workstation-backup"

  export RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-"${config_dir}/profiles/${WORKSTATION_BACKUP_PROFILE}/passwords/${WORKSTATION_BACKUP_PASSWORD}"}"

  if [ -z "${RESTIC_REPOSITORY:-}" ]; then
    export RESTIC_REPOSITORY_FILE="${RESTIC_REPOSITORY_FILE:-"${config_dir}/profiles/${WORKSTATION_BACKUP_PROFILE}/repositories/${WORKSTATION_BACKUP_REPOSITORY}"}"
    export RESTIC_REPOSITORY; RESTIC_REPOSITORY="$(<"${RESTIC_REPOSITORY_FILE}")" || fail
    unset RESTIC_REPOSITORY_FILE
  fi

  export RESTIC_COMPRESSION="${RESTIC_COMPRESSION:-"auto"}"

  "workstation::backup::${action_name}" "$@"
)}

# shellcheck disable=2031
workstation::backup::get_output_folder() {
  if [ -n "${WORKSTATION_BACKUP_OUTPUT:-}" ]; then
    local output_folder="${WORKSTATION_BACKUP_OUTPUT}"
  else
    local output_folder="${HOME}/workstation-backup"
    dir::make_if_not_exists_and_set_permissions "${output_folder}" 0700 || fail

    if [ "${WORKSTATION_BACKUP_PROFILE}" != workstation ]; then
      output_folder+="/${WORKSTATION_BACKUP_PROFILE}"
      dir::make_if_not_exists_and_set_permissions "${output_folder}" 0700 || fail
    fi

    if [ "${WORKSTATION_BACKUP_REPOSITORY}" != default ]; then
      output_folder+="/${WORKSTATION_BACKUP_REPOSITORY}"
      dir::make_if_not_exists_and_set_permissions "${output_folder}" 0700 || fail
    fi
  fi

  echo "${output_folder}"
}
