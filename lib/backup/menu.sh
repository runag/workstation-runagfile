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

workstation::backup::menu() {
  runagfile_menu::display_for workstation::backup::runagfile_menu
  fail_unless_good_code $?
}

workstation::backup::runagfile_menu() {
  runagfile_menu::add --header "Workstation backup deploy" || fail

  runagfile_menu::add workstation::backup::credentials::deploy_remote backup/remotes/personal-backup-server || fail
  runagfile_menu::add workstation::backup::credentials::deploy_profile backup/profiles/workstation || fail

  workstation::backup::runagfile_menu::commands || fail
  workstation::backup::runagfile_menu::services || fail
}

workstation::backup::runagfile_menu::commands() {
  local config_dir="${HOME}/.workstation-backup"

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
        runagfile_menu::add --header "Workstation backup: commands" || fail
        local command; for command in "${commands[@]}"; do
          runagfile_menu::add workstation::backup "${command}" || fail
        done
      else
        runagfile_menu::add --header "Workstation backup: ${repository_name} repository commands" || fail
        local command; for command in "${commands[@]}"; do
          runagfile_menu::add workstation::backup --repository "${repository_name}" "${command}" || fail
        done
      fi
    fi
  done

  if [ "${repository_count}" -gt 1 ]; then
    runagfile_menu::add --header "Workstation backup: for each repository" || fail
    local commands=(init create snapshots check forget prune maintenance unlock restore)
    local command; for command in "${commands[@]}"; do
      runagfile_menu::add workstation::backup --each-repository "${command}" || fail
    done
  fi
}

workstation::backup::runagfile_menu::services() {
  runagfile_menu::add --subheader "Workstation backup: services" || fail

  runagfile_menu::add workstation::backup::services::deploy || fail
  runagfile_menu::add workstation::backup::services::start || fail
  runagfile_menu::add workstation::backup::services::stop || fail
  runagfile_menu::add workstation::backup::services::start_maintenance || fail
  runagfile_menu::add workstation::backup::services::stop_maintenance || fail
  runagfile_menu::add workstation::backup::services::disable_timers || fail
  runagfile_menu::add workstation::backup::services::status || fail
  runagfile_menu::add workstation::backup::services::log || fail
  runagfile_menu::add workstation::backup::services::log_follow || fail
}
