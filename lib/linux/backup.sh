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

# workstation::linux::backup::deploy is the main entrypoint to deploy backup service

if [[ "${OSTYPE}" =~ ^linux ]] && command -v restic >/dev/null && declare -f sopka_menu::add >/dev/null; then
  sopka_menu::add_header "Linux workstation: backup" || fail

  sopka_menu::add workstation::linux::backup::deploy || fail
  sopka_menu::add workstation::linux::backup::create || fail
  sopka_menu::add workstation::linux::backup::list_snapshots || fail
  sopka_menu::add workstation::linux::backup::check_and_read_data || fail
  sopka_menu::add workstation::linux::backup::forget || fail
  sopka_menu::add workstation::linux::backup::prune || fail
  sopka_menu::add workstation::linux::backup::maintenance || fail
  sopka_menu::add workstation::linux::backup::unlock || fail
  sopka_menu::add workstation::linux::backup::mount || fail
  sopka_menu::add workstation::linux::backup::umount || fail
  sopka_menu::add workstation::linux::backup::restore || fail
  sopka_menu::add workstation::linux::backup::shell || fail
  sopka_menu::add workstation::linux::backup::remote_shell || fail

  sopka_menu::add_subheader "Linux workstation: backup services" || fail
  
  sopka_menu::add workstation::linux::backup::start || fail
  sopka_menu::add workstation::linux::backup::stop || fail
  sopka_menu::add workstation::linux::backup::start_maintenance || fail
  sopka_menu::add workstation::linux::backup::stop_maintenance || fail
  sopka_menu::add workstation::linux::backup::disable_timers || fail
  sopka_menu::add workstation::linux::backup::status || fail
  sopka_menu::add workstation::linux::backup::log || fail
  sopka_menu::add workstation::linux::backup::log_follow || fail
fi

workstation::linux::backup::deploy() {
  # required for vmware::get_machine_uuid
  if vmware::is_inside_vm; then
    echo "${USER} ALL=NOPASSWD: /usr/sbin/dmidecode" | file::sudo_write /etc/sudoers.d/dmidecode 440 || fail
  fi

  # install restic key
  dir::make_if_not_exists_and_set_permissions "${MY_KEYS_PATH}" 0700 || fail
  dir::make_if_not_exists_and_set_permissions "${MY_KEYS_PATH}/restic" 0700 || fail
  pass::use "${MY_WORKSTATION_BACKUP_RESTIC_PASSWORD_PATH}" pass::file "${BACKUP_RESTIC_PASSWORD_FILE}" --mode 0600 || fail

  # install ssh key
  ssh::install_ssh_key_from_pass "${MY_WORKSTATION_BACKUP_SSH_KEY_PATH}" || fail

  # install ssh config
  local ssh_key_dir; ssh_key_dir="$(dirname "${MY_WORKSTATION_BACKUP_SSH_KEY_PATH}")" || fail
  pass::use "${ssh_key_dir}/config" --body pass::file "${HOME}/.ssh/config" --mode 0600 || fail

  # add remote to known hosts
  pass::use "${ssh_key_dir}/known_hosts" --body pass::file_with_block "${HOME}/.ssh/known_hosts" "# backup-server" --mode 0600 || fail

  # install systemd services
  workstation::linux::backup::install_systemd_services || fail
}

workstation::linux::backup::with_env() {(
  export RESTIC_PASSWORD_FILE="${BACKUP_RESTIC_PASSWORD_FILE}"
  export RESTIC_REPOSITORY="${BACKUP_RESTIC_REPOSITORY}"
  "$@"
)}

workstation::linux::backup::restic() {(
  workstation::linux::backup::with_env restic "$@"
)}

workstation::linux::backup::install_systemd_services() {
  systemd::write_user_unit "workstation-backup.service" <<EOF || fail
[Unit]
Description=Workstation backup

[Service]
Type=oneshot
ExecStart=${SOPKA_BIN_PATH} workstation::linux::backup::create
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
ExecStart=${SOPKA_BIN_PATH} workstation::linux::backup::maintenance
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

workstation::linux::backup::create() {
  if ! workstation::linux::backup::restic cat config >/dev/null 2>&1; then
    workstation::linux::backup::restic init || fail "Unable to init restic repository"
  fi

  (cd "${HOME}" && workstation::linux::backup::create::perform) || fail "Unable to create restic backup"
}

workstation::linux::backup::create::perform() {
  local machine_id; machine_id="$(os::machine_id)" || fail

  workstation::linux::backup::restic backup \
    --one-file-system \
    --tag "machine-id:${machine_id}" \
    --exclude "${HOME}/Downloads" \
    --exclude "${HOME}/snap" \
    --exclude "${HOME}/.cache" \
    --exclude "${HOME}/.local/share/Trash" \
    . || fail
}

workstation::linux::backup::list_snapshots() {
  workstation::linux::backup::restic snapshots || fail
}

workstation::linux::backup::check_and_read_data() {
  workstation::linux::backup::restic check --check-unused --read-data || fail
}

workstation::linux::backup::forget() {
  workstation::linux::backup::restic forget \
    --group-by "host,paths,tags" \
    --keep-within 14d \
    --keep-within-daily 30d \
    --keep-within-weekly 3m \
    --keep-within-monthly 2y || fail
}

workstation::linux::backup::prune() {
  workstation::linux::backup::restic prune || fail
}

workstation::linux::backup::maintenance() {
  workstation::linux::backup::restic check || fail
  workstation::linux::backup::forget || fail
  workstation::linux::backup::prune || fail
}

workstation::linux::backup::unlock() {
  workstation::linux::backup::restic unlock || fail
}

workstation::linux::backup::mount() {
  mkdir -p "${BACKUP_MOUNT_POINT}" || fail

  if findmnt --mountpoint "${BACKUP_MOUNT_POINT}" >/dev/null; then
    fusermount -u "${BACKUP_MOUNT_POINT}" || fail
  fi

  dir::make_if_not_exists_and_set_permissions "${BACKUP_MOUNT_POINT}" 700 || fail

  workstation::linux::backup::restic mount "${BACKUP_MOUNT_POINT}" || fail
}

workstation::linux::backup::umount() {
  fusermount -u -z "${BACKUP_MOUNT_POINT}" || fail
}

workstation::linux::backup::restore() {
  local snapshot="${1:-"latest"}"

  if [ -d "${BACKUP_RESTORE_PATH}" ]; then
    fail "Restore directory already exists, unable to restore"
  fi

  mkdir -p "${BACKUP_RESTORE_PATH}" || fail

  workstation::linux::backup::restic restore --target "${BACKUP_RESTORE_PATH}" --verify "${snapshot}" || fail
}

workstation::linux::backup::shell() {
  workstation::linux::backup::with_env "${SHELL}"
}

workstation::linux::backup::remote_shell() {
  ssh -t "${BACKUP_REMOTE_HOST}" "cd $(printf "%q" "${BACKUP_REMOTE_PATH}"); exec \"\${SHELL}\" -l"
}


workstation::linux::backup::start() {
  systemctl --user --no-block start "workstation-backup.service" || fail
}

workstation::linux::backup::stop() {
  systemctl --user stop "workstation-backup.service" || fail
}

workstation::linux::backup::start_maintenance() {
  systemctl --user --no-block start "workstation-backup-maintenance.service" || fail
}

workstation::linux::backup::stop_maintenance() {
  systemctl --user stop "workstation-backup-maintenance.service" || fail
}

workstation::linux::backup::disable_timers() {
  systemctl --user stop "workstation-backup.timer" || fail
  systemctl --user stop "workstation-backup-maintenance.timer" || fail

  systemctl --user --quiet disable "workstation-backup.timer" || fail
  systemctl --user --quiet disable "workstation-backup-maintenance.timer" || fail
}

workstation::linux::backup::status() {
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

workstation::linux::backup::log() {
  journalctl --user -u "workstation-backup.service" -u "workstation-backup-maintenance.service" --since today || fail
}

workstation::linux::backup::log_follow() {
  journalctl --user -u "workstation-backup.service" -u "workstation-backup-maintenance.service" --since today --follow || fail
}
