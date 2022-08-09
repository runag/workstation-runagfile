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

if [[ "${OSTYPE}" =~ ^linux ]] && command -v restic >/dev/null && declare -f sopka_menu::add >/dev/null; then
  sopka_menu::add_header "Github repositories backup" || fail
  sopka_menu::add ubuntu_workstation::github_repositories_backup::deploy || fail
  sopka_menu::add ubuntu_workstation::github_repositories_backup::create || fail
  sopka_menu::add_delimiter || fail
  sopka_menu::add ubuntu_workstation::github_repositories_backup::start || fail
  sopka_menu::add ubuntu_workstation::github_repositories_backup::stop || fail
  sopka_menu::add ubuntu_workstation::github_repositories_backup::disable_timers || fail
  sopka_menu::add ubuntu_workstation::github_repositories_backup::status || fail
  sopka_menu::add ubuntu_workstation::github_repositories_backup::log || fail
  sopka_menu::add ubuntu_workstation::github_repositories_backup::log_follow || fail
  sopka_menu::add_delimiter || fail
fi

ubuntu_workstation::github_repositories_backup::deploy() {
  systemd::write_user_unit "github-repositories-backup.service" <<EOF || fail
[Unit]
Description=Github repositories backup

[Service]
Type=oneshot
ExecStart=${SOPKA_BIN_PATH} workstation::backup_my_github_repositories
SyslogIdentifier=github-repositories-backup
ProtectSystem=full
PrivateTmp=true
NoNewPrivileges=true
EOF

  systemd::write_user_unit "github-repositories-backup.timer" <<EOF || fail
[Unit]
Description=Timer for Github repositories backup

[Timer]
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=600

[Install]
WantedBy=timers.target
EOF

  # enable systemd user instance without the need for the user to login
  sudo loginctl enable-linger "${USER}" || fail

  # enable the service and start the timer
  systemctl --user --quiet reenable "github-repositories-backup.timer" || fail
  systemctl --user start "github-repositories-backup.timer" || fail
}

ubuntu_workstation::github_repositories_backup::create() {
  workstation::backup_my_github_repositories || fail
}

ubuntu_workstation::github_repositories_backup::start() {
  systemctl --user --no-block start "github-repositories-backup.service" || fail
}

ubuntu_workstation::github_repositories_backup::stop() {
  systemctl --user stop "github-repositories-backup.service" || fail
}

ubuntu_workstation::github_repositories_backup::disable_timers() {
  systemctl --user stop "github-repositories-backup.timer" || fail
  systemctl --user --quiet disable "github-repositories-backup.timer" || fail
}

ubuntu_workstation::github_repositories_backup::status() {
  systemctl --user status "github-repositories-backup.service"
  printf "\n\n"
  systemctl --user status "github-repositories-backup.timer"
}

ubuntu_workstation::github_repositories_backup::log() {
  journalctl --user -u "github-repositories-backup.service" --since today || fail
}

ubuntu_workstation::github_repositories_backup::log_follow() {
  journalctl --user -u "github-repositories-backup.service" --since today --follow || fail
}
