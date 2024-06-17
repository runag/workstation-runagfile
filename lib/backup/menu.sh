#!/usr/bin/env bash

#  Copyright 2012-2024 Rùnag project contributors
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

workstation::backup::tasks() {
  task::add --header "Workstation backup deploy" || softfail || return $?

  task::add workstation::backup::credentials::deploy_remote backup/remotes/my-backup-server || fail # TODO: list options
  task::add workstation::backup::credentials::deploy_profile backup/profiles/workstation || fail # TODO: list options

  workstation::backup::tasks::commands || fail
  workstation::backup::tasks::services || fail
}

workstation::backup::tasks::commands() {
  local config_dir; config_dir="$(workstation::get_config_path "workstation-backup")" || fail

  local repository_count=0

  local repository_config_path; for repository_config_path in "${config_dir}/profiles/workstation/repositories"/*; do
    if [ -f "${repository_config_path}" ]; then
      local repository_name; repository_name="$(basename "${repository_config_path}")" || fail
      local repository_path; repository_path="$(<"${repository_config_path}")" || fail

      if [[ "${OSTYPE}" =~ ^linux ]] && [[ "${repository_path}" =~ ^(/(media/${USER}|mnt)/[^/]+)/ ]] && ! findmnt --mountpoint "${BASH_REMATCH[1]}" >/dev/null; then
        continue
      fi

      ((repository_count+=1))

      local commands=(init create snapshots check forget prune maintenance unlock mount umount restore shell)

      if [[ "${repository_path}" =~ ^sftp: ]]; then
        commands+=(remote_shell)
      fi

      if [ "${repository_name}" = default ]; then
        task::add --header "Workstation backup: commands" || softfail || return $?
        local command; for command in "${commands[@]}"; do
          task::add workstation::backup "${command}" || softfail || return $?
        done
      else
        task::add --header "Workstation backup: ${repository_name} repository commands" || softfail || return $?
        local command; for command in "${commands[@]}"; do
          task::add workstation::backup --repository "${repository_name}" "${command}" || softfail || return $?
        done
      fi
    fi
  done

  if [ "${repository_count}" -gt 1 ]; then
    task::add --header "Workstation backup: for each repository" || softfail || return $?
    local commands=(init create snapshots check forget prune maintenance unlock restore)
    local command; for command in "${commands[@]}"; do
      task::add workstation::backup --each-repository "${command}" || softfail || return $?
    done
  fi

  if [ "${repository_count}" = 0 ]; then
    task::add --header "Workstation backup: repositories" || softfail || return $?
    task::add --note "No backup repositories found" || softfail || return $?
  fi
}

workstation::backup::tasks::services() {
  task::add --header "Workstation backup: services" || softfail || return $?

  task::add workstation::backup::services::deploy || softfail || return $?
  task::add workstation::backup::services::start || softfail || return $?
  task::add workstation::backup::services::stop || softfail || return $?
  task::add workstation::backup::services::start_maintenance || softfail || return $?
  task::add workstation::backup::services::stop_maintenance || softfail || return $?
  task::add workstation::backup::services::disable_timers || softfail || return $?
  task::add workstation::backup::services::status || softfail || return $?
  task::add workstation::backup::services::log || softfail || return $?
  task::add workstation::backup::services::log_follow || softfail || return $?
}
