#!/usr/bin/env bash

#  Copyright 2012-2021 Stanislav Senotrusov <stan@senotrusov.com>
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

if declare -f sopka::add-menu-item >/dev/null; then
  sopka::add-menu-item workstation-backup::deploy || fail
  sopka::add-menu-item workstation-backup::create || fail
  sopka::add-menu-item workstation-backup::list-snapshots || fail
  sopka::add-menu-item workstation-backup::check-and-read-data || fail
  sopka::add-menu-item workstation-backup::forget-and-prune || fail
  sopka::add-menu-item workstation-backup::maintenance || fail
  sopka::add-menu-item workstation-backup::unlock || fail
  sopka::add-menu-item workstation-backup::mount || fail
  sopka::add-menu-item workstation-backup::umount || fail
  sopka::add-menu-item workstation-backup::start || fail
  sopka::add-menu-item workstation-backup::stop || fail
  sopka::add-menu-item workstation-backup::start-maintenance || fail
  sopka::add-menu-item workstation-backup::stop-maintenance || fail
  sopka::add-menu-item workstation-backup::disable-timers || fail
  sopka::add-menu-item workstation-backup::status || fail
  sopka::add-menu-item workstation-backup::log || fail
fi

workstation-backup::install-restic-password-file() {
  local key="$1"
  ( umask 077 && keys::install-decrypted-file \
    "/media/${USER}/KEYS-DAILY/keys/restic/${key}.restic-password.asc" \
    "${HOME}/.keys/restic/${key}.restic-password"
    ) || fail
}

workstation-backup::deploy() {
  # install bitwarden cli
  bitwarden::install-cli-with-nodejs || fail

  # install gpg keys to decrypt restic key
  ubuntu-workstation::install-all-gpg-keys || fail

  # install restic key
  workstation-backup::install-restic-password-file "stan" || fail

  # install ssh key
  ssh::install-keys "my data server" "id_rsa" || fail

  # save ssh destination
  local sshDestinationFile="${HOME}/.keys/my-data-server.ssh-destination"
  bitwarden::write-password-to-file-if-not-exists "my data server ssh destination" "${sshDestinationFile}" || fail

  (
    unset BW_SESSION

    local remoteHost; remoteHost="$(sed s/.*@// "${sshDestinationFile}")" || fail
    ssh::add-host-to-known-hosts "${remoteHost}" || fail

    echo "${USER} ALL=NOPASSWD: /usr/sbin/dmidecode" | file::sudo-write "/etc/sudoers.d/dmidecode" 440 || fail
  
    # install systemd service
    local unitsPath="${HOME}/.config/systemd/user"
    mkdir -p "${unitsPath}" || fail

    tee "${unitsPath}/workstation-backup.service" <<EOF >/dev/null || fail
[Unit]
Description=Workstation backup

[Service]
Type=oneshot
ExecStart=${SOPKA_BIN_PATH} workstation-backup::create
SyslogIdentifier=workstation-backup
ProtectSystem=full
PrivateTmp=true
NoNewPrivileges=false
EOF

    tee "${unitsPath}/workstation-backup.timer" <<EOF >/dev/null || fail
[Unit]
Description=Backup service timer for workstation backup

[Timer]
OnCalendar=hourly
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF

    tee "${unitsPath}/workstation-backup-maintenance.service" <<EOF >/dev/null || fail
[Unit]
Description=Workstation backup maintenance

[Service]
Type=oneshot
ExecStart=${SOPKA_BIN_PATH} workstation-backup::maintenance
SyslogIdentifier=workstation-backup
ProtectSystem=full
PrivateTmp=true
NoNewPrivileges=false
EOF

    tee "${unitsPath}/workstation-backup-maintenance.timer" <<EOF >/dev/null || fail
[Unit]
Description=Backup service timer for workstation backup maintenance

[Timer]
OnCalendar=monthly
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF

    # enable systemd user instance without the need for the user to login
    sudo loginctl enable-linger "${USER}" || fail

    # enable the service and start the timer
    systemctl --user reenable "workstation-backup.service" || fail
    systemctl --user reenable "workstation-backup.timer" || fail
    systemctl --user start "workstation-backup.timer" || fail

    systemctl --user reenable "workstation-backup-maintenance.service" || fail
    systemctl --user reenable "workstation-backup-maintenance.timer" || fail
    systemctl --user start "workstation-backup-maintenance.timer" || fail
  ) || fail
}

workstation-backup::load-configuration() {
  local machineHostname machineId sshDestination

  machineHostname="$(hostnamectl --static status)" || fail

  if vmware::is-inside-vm; then
    machineId="$(vmware::get-machine-uuid)" || fail
  else
    machineId="$(cat /etc/machine-id)" || fail
  fi

  sshDestination="$(cat "${HOME}/.keys/my-data-server.ssh-destination")" || fail

  export RESTIC_PASSWORD_FILE="${HOME}/.keys/restic/stan.restic-password"
  export RESTIC_REPOSITORY="sftp:${sshDestination}:backups/restic/workstation-backups/${machineHostname}-${machineId}"
}

workstation-backup::create() {
  workstation-backup::load-configuration || fail

  if ! restic cat config >/dev/null 2>&1; then
    restic init || fail
  fi

  (cd "${HOME}" && restic backup --one-file-system --exclude "${HOME}"/'.*' --exclude "${HOME}"/'snap' .) || fail
}

workstation-backup::list-snapshots() {
  workstation-backup::load-configuration || fail
  restic snapshots || fail
}

workstation-backup::check-and-read-data() {
  workstation-backup::load-configuration || fail
  restic check --check-unused --read-data || fail
}

workstation-backup::forget-and-prune() {
  workstation-backup::load-configuration || fail
  restic forget \
    --prune \
    --keep-within 14d \
    --keep-daily 32 \
    --keep-weekly 14 \
    --keep-monthly 25 || fail
}

workstation-backup::maintenance() {
  workstation-backup::load-configuration || fail
  restic check || fail
  workstation-backup::forget-and-prune || fail
}

workstation-backup::unlock() {
  workstation-backup::load-configuration || fail
  restic unlock || fail
}

workstation-backup::mount() {
  workstation-backup::load-configuration || fail

  local mountPoint="${HOME}/workstation-backup"

  if findmnt --mountpoint "${mountPoint}" >/dev/null; then
    fusermount -u "${mountPoint}" || fail
  fi

  mkdir -p "${mountPoint}" || fail
  restic mount "${mountPoint}" || fail
}

workstation-backup::umount() {
  local mountPoint="${HOME}/workstation-backup"
  fusermount -u -z "${mountPoint}" || fail
}

workstation-backup::start() {
  systemctl --user --no-block start "workstation-backup.service" || fail
}

workstation-backup::stop() {
  systemctl --user stop "workstation-backup.service" || fail
}

workstation-backup::start-maintenance() {
  systemctl --user --no-block start "workstation-backup-maintenance.service" || fail
}

workstation-backup::stop-maintenance() {
  systemctl --user stop "workstation-backup-maintenance.service" || fail
}

workstation-backup::disable-timers() {
  systemctl --user stop "workstation-backup.timer" || fail
  systemctl --user stop "workstation-backup-maintenance.timer" || fail
  systemctl --user disable "workstation-backup.timer" || fail
  systemctl --user disable "workstation-backup-maintenance.timer" || fail
}

workstation-backup::status() {
  systemctl --user status "workstation-backup.service"
  systemctl --user status "workstation-backup-maintenance.service"

  printf "\n\n"

  systemctl --user list-timers "workstation-backup.timer" --all || fail
  systemctl --user list-timers "workstation-backup-maintenance.timer" --all || fail

  printf "\n\n"

  systemctl --user status "workstation-backup.timer"
  systemctl --user status "workstation-backup-maintenance.timer"
}

workstation-backup::log() {
  journalctl --user -u "workstation-backup.service" -u "workstation-backup-maintenance.service" --since today || fail
}
