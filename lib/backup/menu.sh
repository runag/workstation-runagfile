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

workstation::backup::populate_runag_menu() {
  local config_dir="${HOME}/.workstation-backup"

  local repository_count=0

  local repository_config_path; for repository_config_path in "${config_dir}/profiles/workstation/repositories"/*; do
    if [ -f "${repository_config_path}" ]; then
      local repository_name; repository_name="$(basename "${repository_config_path}")" || softfail || return $?
      local repository_path; repository_path="$(<"${repository_config_path}")" || softfail || return $?

      if [[ "${OSTYPE}" =~ ^linux ]] && [[ "${repository_path}" =~ ^(/(media/${USER}|mnt)/[^/]+)/ ]] && [ ! -d "${BASH_REMATCH[1]}" ]; then
        continue
      fi

      ((repository_count+=1))

      local commands=(init create snapshots check forget prune maintenance unlock mount umount restore shell)

      if [[ "${repository_path}" =~ ^sftp: ]]; then
        commands+=(remote_shell)
      fi

      if [ "${repository_name}" = default ]; then
        runagfile_menu::add_header "Workstation backup: commands" || softfail || return $?
        local command; for command in "${commands[@]}"; do
          runagfile_menu::add workstation::backup "${command}" || softfail || return $?
        done
      else
        runagfile_menu::add_header "Workstation backup: ${repository_name} repository commands" || softfail || return $?
        local command; for command in "${commands[@]}"; do
          runagfile_menu::add workstation::backup --repository "${repository_name}" "${command}" || softfail || return $?
        done
      fi
    fi
  done

  if [ "${repository_count}" -gt 1 ]; then
    runagfile_menu::add_header "Workstation backup: for each repository" || softfail || return $?
    local commands=(init create snapshots check forget prune maintenance unlock restore)
    local command; for command in "${commands[@]}"; do
      runagfile_menu::add workstation::backup --each-repository "${command}" || softfail || return $?
    done
  fi
}

if runagfile_menu::necessary && command -v restic >/dev/null; then
  runagfile_menu::add_header "Workstation backup" || softfail || return $?

  runagfile_menu::add workstation::backup::credentials::deploy_remote backup/remotes/personal-backup-server || softfail || return $?
  runagfile_menu::add workstation::backup::credentials::deploy_profile backup/profiles/workstation || softfail || return $?

  workstation::backup::populate_runag_menu
  softfail_unless_good "Unable to perform workstation::backup::populate_runag_menu ($?)" $? || true
fi
