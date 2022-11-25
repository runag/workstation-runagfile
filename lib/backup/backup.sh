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

  local each_repository=false

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
    -e|--each-repository)
      each_repository=true
      shift
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

  export RESTIC_COMPRESSION="${RESTIC_COMPRESSION:-"auto"}"

  export RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-"${config_dir}/profiles/${WORKSTATION_BACKUP_PROFILE}/passwords/${WORKSTATION_BACKUP_PASSWORD}"}"

  export RESTIC_REPOSITORY

  if [ "${each_repository}" = true ]; then
    if [ -n "${RESTIC_REPOSITORY:-}" ] || [ -n "${RESTIC_REPOSITORY_FILE:-}" ]; then
      fail "RESTIC_REPOSITORY or RESTIC_REPOSITORY_FILE should not be provided if --each-repository is specified"
    fi

    local exit_statuses=()

    local repository_config_path; for repository_config_path in "${config_dir}/profiles/${WORKSTATION_BACKUP_PROFILE}/repositories"/*; do
      if [ -f "${repository_config_path}" ]; then
        WORKSTATION_BACKUP_REPOSITORY="$(basename "${repository_config_path}")" || softfail || { exit_statuses+=(1); continue; }
        RESTIC_REPOSITORY="$(<"${repository_config_path}")" || softfail || { exit_statuses+=(1); continue; }

        if [[ ! "${RESTIC_REPOSITORY}" =~ .+:.+ ]]; then
          if [[ "${OSTYPE}" =~ ^linux ]]; then
            if [[ "${RESTIC_REPOSITORY}" =~ ^(/(media/${USER}|mnt)/[^/]+)/ ]]; then
              local mount_point="${BASH_REMATCH[1]}"
              if [ ! -d "${mount_point}" ]; then
                continue
              fi

              cd "${mount_point}" || softfail || { exit_statuses+=(1); continue; }
              ( sleep infinity ) &
            fi
          elif [ ! -d "${RESTIC_REPOSITORY}" ]; then
            continue
          fi
        fi

        echo "Proceeding with repository: ${RESTIC_REPOSITORY}"
        "workstation::backup::${action_name}" "$@"
        local action_status=$?
        exit_statuses+=("${action_status}")
        softfail_unless_good "workstation::backup::${action_name} failed (${action_status})" "${action_status}" || true
      fi
    done

    local job_pids; job_pids="$(jobs -p)" || fail

    if [ -n "${job_pids}" ]; then
      # shellcheck disable=2086
      kill ${job_pids} || fail
    fi

    if [[ "${exit_statuses[*]}" =~ [^0[:space:]] ]]; then
      softfail "One or more workstation::backup::${action_name} failed (${exit_statuses[*]})"
      return $?
    fi

  else
    if [ -z "${RESTIC_REPOSITORY:-}" ]; then
      export RESTIC_REPOSITORY_FILE="${RESTIC_REPOSITORY_FILE:-"${config_dir}/profiles/${WORKSTATION_BACKUP_PROFILE}/repositories/${WORKSTATION_BACKUP_REPOSITORY}"}"
      export RESTIC_REPOSITORY; RESTIC_REPOSITORY="$(<"${RESTIC_REPOSITORY_FILE}")" || fail
      unset RESTIC_REPOSITORY_FILE
    fi

    "workstation::backup::${action_name}" "$@"
    softfail_unless_good "workstation::backup::${action_name} failed ($?)" $? || return $?
  fi
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
