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

# shellcheck disable=2030
workstation::backup() (
  export WORKSTATION_BACKUP_PROFILE="workstation"
  export WORKSTATION_BACKUP_PASSWORD="default"
  export WORKSTATION_BACKUP_REPOSITORY="default"

  while [ "$#" -gt 0 ]; do
    case "$1" in
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

  local command_name="$1"; shift

  local config_dir; config_dir="$(workstation::get_config_path "workstation-backup")" || fail

  export RESTIC_COMPRESSION="auto"
  export RESTIC_PASSWORD_FILE="${config_dir}/profiles/${WORKSTATION_BACKUP_PROFILE}/passwords/${WORKSTATION_BACKUP_PASSWORD}"

  unset RESTIC_REPOSITORY
  unset RESTIC_REPOSITORY_FILE

  export RESTIC_REPOSITORY; RESTIC_REPOSITORY="$(<"${config_dir}/profiles/${WORKSTATION_BACKUP_PROFILE}/repositories/${WORKSTATION_BACKUP_REPOSITORY}")" || fail

  "workstation::backup::${command_name}" "$@" || fail
)

# shellcheck disable=2031
workstation::backup::get_output_directory() {
  local output_directory
  if [ -n "${WORKSTATION_BACKUP_OUTPUT_DIR:-}" ]; then
    output_directory="${WORKSTATION_BACKUP_OUTPUT_DIR}"
    ( umask 0077 && mkdir -p "${output_directory}" ) || softfail || return $?
  else
    local data_home="${XDG_DATA_HOME:-"${HOME}/.local/share"}"
    ( umask 0077 && mkdir -p "${data_home}" ) || softfail || return $?

    output_directory="${data_home}/workstation-backup"
    dir::should_exists --mode 0700 "${output_directory}" || softfail || return $?

    file::write --mode 0600 "${output_directory}/.backup-restore-dir-flag" "38pmZzJ687QwThYHkOSGzt" || softfail || return $?

    if [ "${WORKSTATION_BACKUP_PROFILE}" != workstation ]; then
      output_directory+="/${WORKSTATION_BACKUP_PROFILE}"
      dir::should_exists --mode 0700 "${output_directory}" || softfail || return $?
    fi

    if [ "${WORKSTATION_BACKUP_REPOSITORY}" != default ]; then
      output_directory+="/${WORKSTATION_BACKUP_REPOSITORY}"
      dir::should_exists --mode 0700 "${output_directory}" || softfail || return $?
    fi
  fi

  echo "${output_directory}"
}

workstation::backup::configure_passwordless_sudo_for_dmidecode() {
  <<<"${USER} ALL=NOPASSWD: /usr/sbin/dmidecode" file::write --sudo --mode 0440 /etc/sudoers.d/passwordless-dmidecode || softfail || return $?
}

workstation::backup::machine_id() {
  if systemd-detect-virt --quiet && [ -f /etc/sudoers.d/passwordless-dmidecode ]; then
    sudo dmidecode --string system-uuid && return
  fi

  cat /etc/machine-id || softfail || return $?
}

workstation::backup::deploy_services() {
  local runag_path; runag_path="$(command -v runag)" || fail

  systemd::write_user_unit "workstation-backup.service" <<EOF || fail
[Unit]
Description=Workstation backup

[Service]
Type=oneshot
ExecStart=${runag_path} workstation::backup create
SyslogIdentifier=workstation-backup
ProtectSystem=full
PrivateTmp=true
NoNewPrivileges=false
EOF

  systemd::write_user_unit "workstation-backup.timer" <<EOF || fail
[Unit]
Description=Backup service timer for workstation backup

[Timer]
OnCalendar=hourly
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF

  # enable the service and start the timer
  systemctl --user --quiet reenable "workstation-backup.timer" || fail
  systemctl --user start "workstation-backup.timer" || fail
}
