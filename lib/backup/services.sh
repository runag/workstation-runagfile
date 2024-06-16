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

workstation::backup::services::deploy() {
  local runag_path; runag_path="$(command -v runag)" || fail

  systemd::write_user_unit "workstation-backup.service" <<EOF || fail
[Unit]
Description=Workstation backup

[Service]
Type=oneshot
ExecStart=${runag_path} workstation::backup --each-repository create
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
ExecStart=${runag_path} workstation::backup --each-repository maintenance
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

[Install]
WantedBy=timers.target
EOF

  # enable the service and start the timer
  systemctl --user --quiet reenable "workstation-backup.timer" || fail
  systemctl --user start "workstation-backup.timer" || fail

  systemctl --user --quiet reenable "workstation-backup-maintenance.timer" || fail
  systemctl --user start "workstation-backup-maintenance.timer" || fail
}

workstation::backup::services::start() {
  systemctl --user --no-block start "workstation-backup.service" || fail
}

workstation::backup::services::stop() {
  systemctl --user stop "workstation-backup.service" || fail
}

workstation::backup::services::start_maintenance() {
  systemctl --user --no-block start "workstation-backup-maintenance.service" || fail
}

workstation::backup::services::stop_maintenance() {
  systemctl --user stop "workstation-backup-maintenance.service" || fail
}

workstation::backup::services::disable_timers() {
  systemctl --user stop "workstation-backup.timer" || fail
  systemctl --user stop "workstation-backup-maintenance.timer" || fail

  systemctl --user --quiet disable "workstation-backup.timer" || fail
  systemctl --user --quiet disable "workstation-backup-maintenance.timer" || fail
}

workstation::backup::services::status() {
  local exit_statuses=()

  printf "\n"

  systemctl --user list-timers "workstation-backup*.timer" --all || fail
  exit_statuses+=($?)
  printf "\n\n\n"

  systemctl --user status "workstation-backup.timer"
  exit_statuses+=($?)
  printf "\n\n\n"

  systemctl --user status "workstation-backup-maintenance.timer"
  exit_statuses+=($?)
  printf "\n\n\n"

  systemctl --user status "workstation-backup.service"
  exit_statuses+=($?)
  printf "\n\n\n"

  systemctl --user status "workstation-backup-maintenance.service"
  exit_statuses+=($?)
  printf "\n"

  if [[ "${exit_statuses[*]}" =~ [^03[:space:]] ]]; then # I'm not sure about number 3 here
    fail
  fi
}

workstation::backup::services::log() {
  journalctl --user -u "workstation-backup.service" -u "workstation-backup-maintenance.service" --lines 2048 || fail
}

workstation::backup::services::log_follow() {
  journalctl --user -u "workstation-backup.service" -u "workstation-backup-maintenance.service" --lines 2048 --follow || fail
}
