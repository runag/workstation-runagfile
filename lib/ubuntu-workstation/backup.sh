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

# ubuntu_workstation::backup::deploy is the main entrypoint to deploy backup service

if [[ "${OSTYPE}" =~ ^linux ]] && command -v restic >/dev/null && declare -f sopka_menu::add >/dev/null; then
  sopka_menu::add_header Backup || fail
  sopka_menu::add ubuntu_workstation::backup::deploy || fail
  sopka_menu::add ubuntu_workstation::backup::create || fail
  sopka_menu::add ubuntu_workstation::backup::list_snapshots || fail
  sopka_menu::add ubuntu_workstation::backup::check_and_read_data || fail
  sopka_menu::add ubuntu_workstation::backup::forget || fail
  sopka_menu::add ubuntu_workstation::backup::prune || fail
  sopka_menu::add ubuntu_workstation::backup::maintenance || fail
  sopka_menu::add ubuntu_workstation::backup::unlock || fail
  sopka_menu::add ubuntu_workstation::backup::mount || fail
  sopka_menu::add ubuntu_workstation::backup::umount || fail
  sopka_menu::add ubuntu_workstation::backup::restore || fail
  sopka_menu::add ubuntu_workstation::backup::shell || fail
  sopka_menu::add ubuntu_workstation::backup::remote_shell || fail
  sopka_menu::add_delimiter || fail
  sopka_menu::add ubuntu_workstation::backup::start || fail
  sopka_menu::add ubuntu_workstation::backup::stop || fail
  sopka_menu::add ubuntu_workstation::backup::start_maintenance || fail
  sopka_menu::add ubuntu_workstation::backup::stop_maintenance || fail
  sopka_menu::add ubuntu_workstation::backup::disable_timers || fail
  sopka_menu::add ubuntu_workstation::backup::status || fail
  sopka_menu::add ubuntu_workstation::backup::log || fail
  sopka_menu::add ubuntu_workstation::backup::log_follow || fail
  sopka_menu::add_delimiter || fail
fi

ubuntu_workstation::backup::deploy() {
  # required for vmware::get_machine_uuid
  if vmware::is_inside_vm; then
    echo "${USER} ALL=NOPASSWD: /usr/sbin/dmidecode" | file::sudo_write /etc/sudoers.d/dmidecode 440 || fail
  fi

  # install restic key
  workstation::make_keys_directory_if_not_exists || fail
  dir::make_if_not_exists_and_set_permissions "${MY_KEYS_PATH}/restic" 700 || fail
  pass::use "${MY_WORKSTATION_BACKUP_RESTIC_PASSWORD_PATH}" pass::file "${BACKUP_RESTIC_PASSWORD_FILE}" --mode 0600 || fail

  # install ssh key
  ssh::install_ssh_key_from_pass "${MY_WORKSTATION_BACKUP_SSH_KEY_PATH}" || fail

  # install ssh config
  local ssh_key_dir; ssh_key_dir="$(dirname "${MY_WORKSTATION_BACKUP_SSH_KEY_PATH}")" || fail
  pass::use "${ssh_key_dir}/config" --body pass::file "${HOME}/.ssh/config" --mode 0600 || fail

  # add remote to known hosts
  pass::use "${ssh_key_dir}/known_hosts" --body pass::file_with_block "${HOME}/.ssh/known_hosts" "# backup-server" --mode 0600 || fail

  # install systemd services
  ubuntu_workstation::backup::install_systemd_services || fail
}

ubuntu_workstation::backup::with_env() {(
  export RESTIC_PASSWORD_FILE="${BACKUP_RESTIC_PASSWORD_FILE}"
  export RESTIC_REPOSITORY="${BACKUP_RESTIC_REPOSITORY}"
  "$@"
)}

ubuntu_workstation::backup::restic() {(
  ubuntu_workstation::backup::with_env restic "$@"
)}

ubuntu_workstation::backup::install_systemd_services() {
  systemd::write_user_unit "workstation-backup.service" <<EOF || fail
[Unit]
Description=Workstation backup

[Service]
Type=oneshot
ExecStart=${SOPKA_BIN_PATH} ubuntu_workstation::backup::create
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

  systemd::write_user_unit "workstation-backup-maintenance.service" <<EOF || fail
[Unit]
Description=Workstation backup maintenance

[Service]
Type=oneshot
ExecStart=${SOPKA_BIN_PATH} ubuntu_workstation::backup::maintenance
SyslogIdentifier=workstation-backup
ProtectSystem=full
PrivateTmp=true
NoNewPrivileges=false
EOF

  systemd::write_user_unit "workstation-backup-maintenance.timer" <<EOF || fail
[Unit]
Description=Backup service timer for workstation backup maintenance

[Timer]
OnCalendar=weekly
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF

  # enable systemd user instance without the need for the user to login
  sudo loginctl enable-linger "${USER}" || fail

  # enable the service and start the timer
  systemctl --user --quiet reenable "workstation-backup.timer" || fail
  systemctl --user start "workstation-backup.timer" || fail

  systemctl --user --quiet reenable "workstation-backup-maintenance.timer" || fail
  systemctl --user start "workstation-backup-maintenance.timer" || fail
}

ubuntu_workstation::backup::create() {
  if ! ubuntu_workstation::backup::restic cat config >/dev/null 2>&1; then
    ubuntu_workstation::backup::restic init || fail "Unable to init restic repository"
  fi

  (cd "${HOME}" && ubuntu_workstation::backup::create::perform) || fail "Unable to create restic backup"
}

ubuntu_workstation::backup::create::perform() {
  local machine_id; machine_id="$(os::machine_id)" || fail

  ubuntu_workstation::backup::restic backup \
    --one-file-system \
    --tag "machine-id:${machine_id}" \
    --exclude "${HOME}/Downloads" \
    --exclude "${HOME}/snap" \
    --exclude "${HOME}/.cache" \
    --exclude "${HOME}/.local/share/Trash" \
    . || fail
}

ubuntu_workstation::backup::list_snapshots() {
  ubuntu_workstation::backup::restic snapshots || fail
}

ubuntu_workstation::backup::check_and_read_data() {
  ubuntu_workstation::backup::restic check --check-unused --read-data || fail
}

ubuntu_workstation::backup::forget() {
  ubuntu_workstation::backup::restic forget \
    --group-by "host,paths,tags" \
    --keep-within 14d \
    --keep-within-daily 30d \
    --keep-within-weekly 3m \
    --keep-within-monthly 2y || fail
}

ubuntu_workstation::backup::prune() {
  ubuntu_workstation::backup::restic prune || fail
}

ubuntu_workstation::backup::maintenance() {
  ubuntu_workstation::backup::restic check || fail
  ubuntu_workstation::backup::forget || fail
  ubuntu_workstation::backup::prune || fail
}

ubuntu_workstation::backup::unlock() {
  ubuntu_workstation::backup::restic unlock || fail
}

ubuntu_workstation::backup::mount() {
  mkdir -p "${BACKUP_MOUNT_POINT}" || fail

  if findmnt --mountpoint "${BACKUP_MOUNT_POINT}" >/dev/null; then
    fusermount -u "${BACKUP_MOUNT_POINT}" || fail
  fi

  dir::make_if_not_exists_and_set_permissions "${BACKUP_MOUNT_POINT}" 700 || fail

  ubuntu_workstation::backup::restic mount "${BACKUP_MOUNT_POINT}" || fail
}

ubuntu_workstation::backup::umount() {
  fusermount -u -z "${BACKUP_MOUNT_POINT}" || fail
}

ubuntu_workstation::backup::restore() {
  local snapshot="${1:-"latest"}"

  if [ -d "${BACKUP_RESTORE_PATH}" ]; then
    fail "Restore directory already exists, unable to restore"
  fi

  mkdir -p "${BACKUP_RESTORE_PATH}" || fail

  ubuntu_workstation::backup::restic restore --target "${BACKUP_RESTORE_PATH}" --verify "${snapshot}" || fail
}

ubuntu_workstation::backup::shell() {
  ubuntu_workstation::backup::with_env "${SHELL}"
}

ubuntu_workstation::backup::remote_shell() {
  ssh -t "${BACKUP_REMOTE_HOST}" "cd $(printf "%q" "${BACKUP_REMOTE_PATH}"); exec \"\${SHELL}\" -l"
}


ubuntu_workstation::backup::start() {
  systemctl --user --no-block start "workstation-backup.service" || fail
}

ubuntu_workstation::backup::stop() {
  systemctl --user stop "workstation-backup.service" || fail
}

ubuntu_workstation::backup::start_maintenance() {
  systemctl --user --no-block start "workstation-backup-maintenance.service" || fail
}

ubuntu_workstation::backup::stop_maintenance() {
  systemctl --user stop "workstation-backup-maintenance.service" || fail
}

ubuntu_workstation::backup::disable_timers() {
  systemctl --user stop "workstation-backup.timer" || fail
  systemctl --user stop "workstation-backup-maintenance.timer" || fail

  systemctl --user --quiet disable "workstation-backup.timer" || fail
  systemctl --user --quiet disable "workstation-backup-maintenance.timer" || fail
}

ubuntu_workstation::backup::status() {
  systemctl --user status "workstation-backup.service"
  systemctl --user status "workstation-backup-maintenance.service"

  # printf "\n\n"
  #
  # systemctl --user list-timers "workstation-backup.timer" --all || fail
  # systemctl --user list-timers "workstation-backup-maintenance.timer" --all || fail

  printf "\n\n"

  systemctl --user status "workstation-backup.timer"
  systemctl --user status "workstation-backup-maintenance.timer"
}

ubuntu_workstation::backup::log() {
  journalctl --user -u "workstation-backup.service" -u "workstation-backup-maintenance.service" --since today || fail
}

ubuntu_workstation::backup::log_follow() {
  journalctl --user -u "workstation-backup.service" -u "workstation-backup-maintenance.service" --since today --follow || fail
}
