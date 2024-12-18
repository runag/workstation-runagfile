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
  # Workstation backup: deploy (task header)
  task::add workstation::backup::deploy || softfail || return $?

  # Workstation backup: commands (task header)

  local commands=(
    create
    mount
    prune
    restore
    shell
    umount
    )

  local command; for command in "${commands[@]}"; do
    task::add workstation::backup "${command}" || softfail || return $?
  done

  systemd::service_tasks --user --with-timer --service-name "workstation-backup" || softfail || return $?
}

workstation::backup::deploy() {
  # In order for backup to work, configure passwordless sudo for dmidecode in get machine uuid
  if systemd-detect-virt --quiet; then
    <<<"${USER} ALL=NOPASSWD: /usr/sbin/dmidecode" file::write --sudo --mode 0440 /etc/sudoers.d/passwordless-dmidecode || fail
    local no_new_privileges=false
  else
    local no_new_privileges=true
  fi

  local passwords_dir; passwords_dir="$(workstation::get_config_dir "backup/passwords")" || fail
  local repositories_dir; repositories_dir="$(workstation::get_config_dir "backup/repositories")" || fail
  
  pass::use "backup/passwords/workstation" file::write --mode 0600 "${passwords_dir}/workstation" || fail
  pass::use "backup/repositories/workstation" file::write --mode 0600 "${repositories_dir}/workstation" || fail

  ssh::add_ssh_config_d_include_directive || fail

  runag pass::each --directory "backup/remotes/sftp" workstation::backup::deploy_sftp_remote || fail

  local temp_file; temp_file="$(mktemp)" || fail
  {
    runag::mini_library --nounset || fail
 
    declare -f dir::should_exists || fail
    declare -f workstation::get_config_dir || fail

    declare -f workstation::backup || fail
    declare -f workstation::backup::create || fail
    declare -f workstation::backup::machine_id || fail

    echo 'workstation::backup create || fail'

  } >"${temp_file}" || fail

  local service_name="workstation-backup"
  local bin_dir="${HOME}/.local/bin"
  local bin_path="${bin_dir}/create-${service_name}"

  dir::should_exists "${bin_dir}" || fail
  file::write --absorb "${temp_file}" --mode 0755 "${bin_path}" || fail

  systemd::write_user_unit "${service_name}.service" <<EOF || fail
[Unit]
Description=${service_name}

[Service]
Type=oneshot
ExecStart=${bin_path}
WorkingDirectory=${HOME}

SyslogIdentifier=${service_name}

NoNewPrivileges=${no_new_privileges}
EOF

  systemd::write_user_unit "${service_name}.timer" <<EOF || fail
[Unit]
Description=${service_name} timer

[Timer]
OnCalendar=hourly
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF

  # enable the service and start the timer
  systemctl --user --quiet reenable "${service_name}.timer" || fail
  systemctl --user start "${service_name}.timer" || fail
}

workstation::backup::deploy_sftp_remote() {
  local path="$1"
  local base_name; base_name="$(basename "${path}")" || fail

  ssh::install_ssh_profile_from_pass --profile-name "workstation-backup-${base_name}" "${path}" || fail
}

# shellcheck disable=2030
workstation::backup() (
  local config_dir; config_dir="$(workstation::get_config_dir "backup")" || fail

  export RESTIC_PASSWORD_FILE="${config_dir}/passwords/workstation"
  export RESTIC_REPOSITORY_FILE="${config_dir}/repositories/workstation"
  export RESTIC_COMPRESSION="auto"

  local command_name="$1"; shift

  "workstation::backup::${command_name}" "$@" || fail
)

workstation::backup::create() (
  local machine_id; machine_id="$(workstation::backup::machine_id)" || fail

  cd "${HOME}" || fail

  # https://restic.readthedocs.io/en/stable/040_backup.html#excluding-files
  local exclude_args=(
    --exclude  "${HOME}/.*"
   
    --exclude "!${HOME}/.gnupg"
    --exclude "!${HOME}/.password-store"
    --exclude "!${HOME}/.runag"
    --exclude "!${HOME}/.ssh"

    --exclude  "${HOME}/snap"
    --iexclude "${HOME}/sync"
    --iexclude "${HOME}/downloads"
    )

  restic backup \
    --one-file-system \
    --tag "machine-id:${machine_id}" \
    --group-by "host,paths,tags" \
    "${exclude_args[@]}" \
    . || fail
)

workstation::backup::machine_id() {
  if systemd-detect-virt --quiet && [ -f /etc/sudoers.d/passwordless-dmidecode ]; then
    sudo dmidecode --string system-uuid && return 0
  fi

  cat /etc/machine-id || fail
}

workstation::backup::prune() {
  restic check || fail

  restic forget \
    --group-by "host,paths,tags" \
    --keep-within 14d \
    --keep-within-daily 30d \
    --keep-within-weekly 3m \
    --keep-within-monthly 3y || fail

  restic prune || fail
}

workstation::backup::shell() {
  exec "${SHELL}"
}

workstation::backup::mount() {
  local mount_directory="${XDG_DATA_HOME:-"${HOME}/.local/share"}/backup/mount" || fail
  dir::should_exists --for-me-only "${mount_directory}" || fail
  
  if findmnt --mountpoint "${mount_directory}" >/dev/null; then
    fusermount3 -u -z "${mount_directory}" || fail
  fi

  restic::open_mount_when_available "${mount_directory}" || fail
  local open_mount_pid=$!

  if ! restic mount --owner-root "${mount_directory}"; then
    kill "${open_mount_pid}"
    fail
  fi
}

workstation::backup::umount() {
  local mount_directory="${XDG_DATA_HOME:-"${HOME}/.local/share"}/backup/mount" || fail
  fusermount3 -u -z "${mount_directory}" || fail
}

workstation::backup::restore() {
  local snapshot_id="${1:-"latest"}"

  local restore_directory="${XDG_DATA_HOME:-"${HOME}/.local/share"}/backup/${snapshot_id}" || fail

  if [ -d "${restore_directory}" ]; then
    fail "Restore directory already exists, unable to restore"
  fi

  dir::should_exists --for-me-only "${restore_directory}" || fail

  restic restore --target "${restore_directory}" "${snapshot_id}" || fail
}
