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
