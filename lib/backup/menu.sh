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

workstation::backup::populate_sopka_menu() {
  local config_dir="${HOME}/.workstation-backup"

  local repository_config_path; for repository_config_path in "${config_dir}/profiles/workstation/repositories"/*; do
    if [ -f "${repository_config_path}" ]; then
      local repository_name; repository_name="$(basename "${repository_config_path}")" || softfail || return $?
      local repository_path; repository_path="$(<"${repository_config_path}")" || softfail || return $?

      if [[ "${OSTYPE}" =~ ^linux ]] && [[ "${repository_path}" =~ ^(/(media/${USER}|mnt)/[^/]+)/ ]] && [ ! -d "${BASH_REMATCH[1]}" ]; then
        continue
      fi

      if [ "${repository_name}" = default ]; then
        sopkafile_menu::add_header "Workstation backup: commands" || softfail || return $?

        workstation::backup::populate_sopka_menu_with_commands || softfail || return $?
      else
        sopkafile_menu::add_header "Workstation backup: ${repository_name} repository commands" || softfail || return $?
        
        workstation::backup::populate_sopka_menu_with_commands --repository "${repository_name}" || softfail || return $?
      fi
    fi
  done
}

workstation::backup::populate_sopka_menu_with_commands() {
  sopkafile_menu::add workstation::backup "$@" create || softfail || return $?
  sopkafile_menu::add workstation::backup "$@" snapshots || softfail || return $?
  sopkafile_menu::add workstation::backup "$@" check || softfail || return $?
  sopkafile_menu::add workstation::backup "$@" forget || softfail || return $?
  sopkafile_menu::add workstation::backup "$@" prune || softfail || return $?
  sopkafile_menu::add workstation::backup "$@" maintenance || softfail || return $?
  sopkafile_menu::add workstation::backup "$@" unlock || softfail || return $?
  sopkafile_menu::add workstation::backup "$@" mount || softfail || return $?
  sopkafile_menu::add workstation::backup "$@" umount || softfail || return $?
  sopkafile_menu::add workstation::backup "$@" restore || softfail || return $?
  sopkafile_menu::add workstation::backup "$@" shell || softfail || return $?
  sopkafile_menu::add workstation::backup "$@" remote_shell || softfail || return $?
}

if sopkafile_menu::necessary && command -v restic >/dev/null; then
  sopkafile_menu::add_header "Workstation backup" || fail

  sopkafile_menu::add workstation::backup::credentials::deploy_profile backup/profiles/workstation || fail
  sopkafile_menu::add workstation::backup::credentials::deploy_remote backup/remotes/personal-backup-server || fail

  workstation::backup::populate_sopka_menu
  softfail_unless_good "Unable to perform workstation::backup::populate_sopka_menu ($?)" $? || true
fi
