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

  task::add workstation::backup::credentials::deploy_remote backup/remotes/my-backup-server || softfail || return $? # TODO: list options
  task::add workstation::backup::credentials::deploy_profile backup/profiles/workstation || softfail || return $? # TODO: list options

  workstation::backup::tasks::commands || softfail || return $?
  workstation::backup::tasks::services || softfail || return $?
}

workstation::backup::tasks::commands() {
  local config_dir; config_dir="$(workstation::get_config_path "workstation-backup")" || softfail || return $?

  local repository_config_path; for repository_config_path in "${config_dir}/profiles/workstation/repositories"/*; do
    if [ -f "${repository_config_path}" ]; then
      local repository_name; repository_name="$(basename "${repository_config_path}")" || softfail || return $?
      local repository_path; repository_path="$(<"${repository_config_path}")" || softfail || return $?

      local commands=(init create snapshots check forget prune maintenance unlock mount umount restore shell)

      if [[ "${repository_path}" =~ ^sftp: ]]; then
        commands+=(remote_shell)
      fi

      task::add --header "Workstation backup: ${repository_name} repository commands" || softfail || return $?

      local command; for command in "${commands[@]}"; do
        task::add workstation::backup --repository "${repository_name}" "${command}" || softfail || return $?
      done
    fi
  done
}

workstation::backup::tasks::services() {
  task::add --header "Workstation backup: services" || softfail || return $?

  task::add workstation::backup::services::deploy || softfail || return $?
  task::add workstation::backup::services::start || softfail || return $?
  task::add workstation::backup::services::stop || softfail || return $?
  task::add workstation::backup::services::disable_timers || softfail || return $?
  task::add workstation::backup::services::status || softfail || return $?
  task::add workstation::backup::services::log || softfail || return $?
  task::add workstation::backup::services::log_follow || softfail || return $?
}
