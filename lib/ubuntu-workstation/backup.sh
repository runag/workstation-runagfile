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

if declare -f sopka-menu::add >/dev/null; then
  sopka-menu::add ubuntu-workstation::backup::deploy || fail
  sopka-menu::add ubuntu-workstation::backup::create || fail
  sopka-menu::add ubuntu-workstation::backup::list-snapshots || fail
  sopka-menu::add ubuntu-workstation::backup::check-and-read-data || fail
  sopka-menu::add ubuntu-workstation::backup::forget-and-prune || fail
  sopka-menu::add ubuntu-workstation::backup::perform-maintenance || fail
  sopka-menu::add ubuntu-workstation::backup::unlock || fail
  sopka-menu::add ubuntu-workstation::backup::mount || fail
  sopka-menu::add ubuntu-workstation::backup::umount || fail
  sopka-menu::add ubuntu-workstation::backup::start || fail
  sopka-menu::add ubuntu-workstation::backup::stop || fail
  sopka-menu::add ubuntu-workstation::backup::start-maintenance || fail
  sopka-menu::add ubuntu-workstation::backup::stop-maintenance || fail
  sopka-menu::add ubuntu-workstation::backup::disable-timers || fail
  sopka-menu::add ubuntu-workstation::backup::status || fail
  sopka-menu::add ubuntu-workstation::backup::log || fail
fi

ubuntu-workstation::backup::install-restic-password-file() {
  local key="$1"

  workstation::make-keys-directory-if-not-exists || fail
  dir::make-if-not-exists-but-chmod-anyway "${HOME}/.keys/restic" 700 || fail

  keys::install-decrypted-file \
    "/media/${USER}/KEYS-DAILY/keys/restic/${key}.restic-password.asc" \
    "${HOME}/.keys/restic/${key}.restic-password" || fail
}

ubuntu-workstation::backup::deploy() {
  # install bitwarden cli
  ubuntu-workstation::deploy-bitwarden || fail

  # install gpg keys to decrypt restic key
  ubuntu-workstation::install-all-gpg-keys || fail

  # install restic key
  ubuntu-workstation::backup::install-restic-password-file "stan" || fail

  # install ssh key
  ssh::make-user-config-directory-if-not-exists || fail
  bitwarden::write-notes-to-file-if-not-exists "my data server ssh private key" "${HOME}/.ssh/id_rsa" || fail
  bitwarden::write-notes-to-file-if-not-exists "my data server ssh public key" "${HOME}/.ssh/id_rsa.pub" || fail

  # save ssh destination
  workstation::make-keys-directory-if-not-exists || fail
  bitwarden::write-password-to-file-if-not-exists "my data server ssh destination" "${HOME}/.keys/my-data-server.ssh-destination" || fail

  bitwarden::beyond-session task::run ubuntu-workstation::backup::deploy::stage-2 || fail
}

ubuntu-workstation::backup::deploy::stage-2() {
  local remoteHost; remoteHost="$(sed s/.*@// "${HOME}/.keys/my-data-server.ssh-destination")" || fail
  ssh::add-host-to-known-hosts "${remoteHost}" || fail

  echo "${USER} ALL=NOPASSWD: /usr/sbin/dmidecode" | file::sudo-write /etc/sudoers.d/dmidecode 440 || fail

  ubuntu-workstation::backup::install-systemd-services || fail
}

ubuntu-workstation::backup::install-systemd-services() {
  systemd::write-user-unit "workstation-backup.service" <<EOF || fail
[Unit]
Description=Workstation backup

[Service]
Type=oneshot
ExecStart=${SOPKA_BIN_PATH} ubuntu-workstation::backup::create
SyslogIdentifier=workstation-backup
ProtectSystem=full
PrivateTmp=true
NoNewPrivileges=false
EOF

  systemd::write-user-unit "workstation-backup.timer" <<EOF || fail
[Unit]
Description=Backup service timer for workstation backup

[Timer]
OnCalendar=hourly
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF

  systemd::write-user-unit "workstation-backup-maintenance.service" <<EOF || fail
[Unit]
Description=Workstation backup maintenance

[Service]
Type=oneshot
ExecStart=${SOPKA_BIN_PATH} ubuntu-workstation::backup::perform-maintenance
SyslogIdentifier=workstation-backup
ProtectSystem=full
PrivateTmp=true
NoNewPrivileges=false
EOF

  systemd::write-user-unit "workstation-backup-maintenance.timer" <<EOF || fail
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

  systemctl --user daemon-reload || fail

  # enable the service and start the timer
  systemctl --user reenable "workstation-backup.timer" || fail
  systemctl --user start "workstation-backup.timer" || fail

  systemctl --user reenable "workstation-backup-maintenance.timer" || fail
  systemctl --user start "workstation-backup-maintenance.timer" || fail
}

ubuntu-workstation::backup::load-config() {
  local machineHostname machineId sshDestination

  machineHostname="$(hostname)" || fail

  if vmware::is-inside-vm; then
    machineId="$(vmware::get-machine-uuid)" || fail
  else
    machineId="$(cat /etc/machine-id)" || fail
  fi

  sshDestination="$(cat "${HOME}/.keys/my-data-server.ssh-destination")" || fail

  export RESTIC_PASSWORD_FILE="${HOME}/.keys/restic/stan.restic-password"
  export RESTIC_REPOSITORY="sftp:${sshDestination}:backups/restic/workstation-backups/${machineHostname}-${machineId}"
}

ubuntu-workstation::backup::create() {
  ubuntu-workstation::backup::load-config || fail

  if ! restic cat config >/dev/null 2>&1; then
    restic init || fail
  fi

  (cd "${HOME}" && restic backup --one-file-system --exclude "${HOME}"/'.*' --exclude "${HOME}"/'snap' .) || fail
}

ubuntu-workstation::backup::list-snapshots() {
  ubuntu-workstation::backup::load-config || fail
  restic snapshots || fail
}

ubuntu-workstation::backup::check-and-read-data() {
  ubuntu-workstation::backup::load-config || fail
  restic check --check-unused --read-data || fail
}

ubuntu-workstation::backup::forget-and-prune() {
  ubuntu-workstation::backup::load-config || fail
  restic forget \
    --prune \
    --keep-within 14d \
    --keep-daily 32 \
    --keep-weekly 14 \
    --keep-monthly 25 || fail
}

ubuntu-workstation::backup::perform-maintenance() {
  ubuntu-workstation::backup::load-config || fail
  restic check || fail
  ubuntu-workstation::backup::forget-and-prune || fail
}

ubuntu-workstation::backup::unlock() {
  ubuntu-workstation::backup::load-config || fail
  restic unlock || fail
}

ubuntu-workstation::backup::mount() {
  ubuntu-workstation::backup::load-config || fail

  local mountPoint="${HOME}/workstation-backup"

  if findmnt --mountpoint "${mountPoint}" >/dev/null; then
    fusermount -u "${mountPoint}" || fail
  fi

  dir::make-if-not-exists-but-chmod-anyway "${mountPoint}" 700 || fail

  restic mount "${mountPoint}" || fail
}

ubuntu-workstation::backup::umount() {
  local mountPoint="${HOME}/workstation-backup"
  fusermount -u -z "${mountPoint}" || fail
}

ubuntu-workstation::backup::start() {
  systemctl --user --no-block start "workstation-backup.service" || fail
}

ubuntu-workstation::backup::stop() {
  systemctl --user stop "workstation-backup.service" || fail
}

ubuntu-workstation::backup::start-maintenance() {
  systemctl --user --no-block start "workstation-backup-maintenance.service" || fail
}

ubuntu-workstation::backup::stop-maintenance() {
  systemctl --user stop "workstation-backup-maintenance.service" || fail
}

ubuntu-workstation::backup::disable-timers() {
  systemctl --user stop "workstation-backup.timer" || fail
  systemctl --user stop "workstation-backup-maintenance.timer" || fail
  systemctl --user disable "workstation-backup.timer" || fail
  systemctl --user disable "workstation-backup-maintenance.timer" || fail
}

ubuntu-workstation::backup::status() {
  systemctl --user status "workstation-backup.service"
  systemctl --user status "workstation-backup-maintenance.service"

  printf "\n\n"

  systemctl --user list-timers "workstation-backup.timer" --all || fail
  systemctl --user list-timers "workstation-backup-maintenance.timer" --all || fail

  printf "\n\n"

  systemctl --user status "workstation-backup.timer"
  systemctl --user status "workstation-backup-maintenance.timer"
}

ubuntu-workstation::backup::log() {
  journalctl --user -u "workstation-backup.service" -u "workstation-backup-maintenance.service" --since today || fail
}
