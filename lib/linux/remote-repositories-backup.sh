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
  sopka_menu::add_header "Linux workstation: remote repositories backup services" || fail

  sopka_menu::add workstation::linux::remote_repositories_backup::deploy_credentials identity/personal || fail
  sopka_menu::add workstation::linux::remote_repositories_backup::create || fail
  sopka_menu::add workstation::linux::remote_repositories_backup::deploy_services || fail
  sopka_menu::add workstation::linux::remote_repositories_backup::start || fail
  sopka_menu::add workstation::linux::remote_repositories_backup::stop || fail
  sopka_menu::add workstation::linux::remote_repositories_backup::disable_timers || fail
  sopka_menu::add workstation::linux::remote_repositories_backup::status || fail
  sopka_menu::add workstation::linux::remote_repositories_backup::log || fail
  sopka_menu::add workstation::linux::remote_repositories_backup::log_follow || fail
fi

workstation::linux::remote_repositories_backup::deploy_credentials() {
  local credentials_path="$1"
  local credentials_name; credentials_name="${2:-"$(basename "${credentials_path}")"}" || fail

  local config_dir="${HOME}/.remote-repositories-backup"

  dir::make_if_not_exists_and_set_permissions "${config_dir}" 0700 || fail
  dir::make_if_not_exists_and_set_permissions "${config_dir}/github" 0700 || fail
  dir::make_if_not_exists_and_set_permissions "${config_dir}/github/${credentials_name}" 0700 || fail

  pass::use "${credentials_path}/github/username" file::write --mode 0600 "${config_dir}/github/${credentials_name}/username" || fail
  pass::use "${credentials_path}/github/personal-access-token" file::write --mode 0600 "${config_dir}/github/${credentials_name}/personal-access-token" || fail
}

# shellcheck disable=2030
workstation::linux::remote_repositories_backup::create() {
  local backup_path="${HOME}/remote-repositories-backup"

  dir::make_if_not_exists_and_set_permissions "${backup_path}" 0700 || fail
  dir::make_if_not_exists_and_set_permissions "${backup_path}/github" 0700 || fail

  local config_dir="${HOME}/.remote-repositories-backup"

  local exit_status=0

  local credentials_path; for credentials_path in "${config_dir}/github"/*; do
    if [ -d "${credentials_path}" ]; then
      local credentials_name; credentials_name="${2:-"$(basename "${credentials_path}")"}" || fail

      local GITHUB_USERNAME; GITHUB_USERNAME="$(<"${credentials_path}"/username)"
      local GITHUB_PERSONAL_ACCESS_TOKEN; GITHUB_PERSONAL_ACCESS_TOKEN="$(<"${credentials_path}"/personal-access-token)"

      workstation::linux::remote_repositories_backup::backup_github_repositories "${backup_path}/github/${credentials_name}" || exit_status=1
    fi
  done

  if [ "${exit_status}" != 0 ]; then
    fail
  fi
}

# shellcheck disable=2031
workstation::linux::remote_repositories_backup::backup_github_repositories() {
  local backup_path="$1"

  # NOTE: There is a 100 000 (1000*100) repository limit here. I put it here to not suffer an infinite loop if something is wrong
  local page_number_limit=1000

  local full_name git_url

  local fail_flag; fail_flag="$(mktemp -u)" || fail

  dir::make_if_not_exists_and_set_permissions "${backup_path}" 0700 || fail

  # url to obtain a list of public repos for the specific user "https://api.github.com/users/${GITHUB_USERNAME}/repos?page=${page_number}&per_page=100"

  local page_number; for ((page_number=1; page_number<=page_number_limit; page_number++)); do
    curl \
      --fail \
      --retry 5 \
      --retry-connrefused \
      --show-error \
      --silent \
      --url "https://api.github.com/user/repos?page=${page_number}&per_page=100&visibility=all" \
      --user "${GITHUB_USERNAME}:${GITHUB_PERSONAL_ACCESS_TOKEN}" |\
    jq '.[] | [.full_name, .html_url] | @tsv' --raw-output --exit-status |\
    while IFS=$'\t' read -r full_name git_url; do
      log::notice "Backing up ${backup_path}/${full_name}..." || fail
      git::create_or_update_mirror "${git_url}" "${backup_path}/${full_name}" || touch "${fail_flag}"
    done

    local saved_pipe_status=("${PIPESTATUS[@]}")

    if [ "${saved_pipe_status[*]}" = "0 4 0" ]; then
      if [ -f "${fail_flag}" ]; then
        rm "${fail_flag}" || fail
        fail
      fi
      return
    elif [ "${saved_pipe_status[*]}" != "0 0 0" ]; then
      fail "Abnormal termination: ${saved_pipe_status[*]}"
    fi
  done

  if [ "$page_number" -gt "$page_number_limit" ]; then
    fail "page number limit reached"
  fi

  if [ -f "${fail_flag}" ]; then
    rm "${fail_flag}" || fail
    fail
  fi
}

workstation::linux::remote_repositories_backup::deploy_services() {
  systemd::write_user_unit "remote-repositories-backup.service" <<EOF || fail
[Unit]
Description=Remote repositories backup

[Service]
Type=oneshot
ExecStart=${SOPKA_BIN_PATH} workstation::linux::remote_repositories_backup::create
SyslogIdentifier=remote-repositories-backup
ProtectSystem=full
PrivateTmp=true
NoNewPrivileges=true
EOF

  systemd::write_user_unit "remote-repositories-backup.timer" <<EOF || fail
[Unit]
Description=Timer for remote repositories backup

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=600

[Install]
WantedBy=timers.target
EOF

  # enable the service and start the timer
  systemctl --user --quiet reenable "remote-repositories-backup.timer" || fail
  systemctl --user start "remote-repositories-backup.timer" || fail
}

workstation::linux::remote_repositories_backup::start() {
  systemctl --user --no-block start "remote-repositories-backup.service" || fail
}

workstation::linux::remote_repositories_backup::stop() {
  systemctl --user stop "remote-repositories-backup.service" || fail
}

workstation::linux::remote_repositories_backup::disable_timers() {
  systemctl --user stop "remote-repositories-backup.timer" || fail
  systemctl --user --quiet disable "remote-repositories-backup.timer" || fail
}

workstation::linux::remote_repositories_backup::status() {
  local exit_statuses=()

  printf "\n"
  systemctl --user status "remote-repositories-backup.service"
  exit_statuses+=($?)
  printf "\n\n\n"

  systemctl --user status "remote-repositories-backup.timer"
  exit_statuses+=($?)
  printf "\n"

  if [[ "${exit_statuses[*]}" =~ [^03[:space:]] ]]; then # i'm not sure about 3 here
    fail
  fi
}

workstation::linux::remote_repositories_backup::log() {
  journalctl --user -u "remote-repositories-backup.service" --since today || fail
}

workstation::linux::remote_repositories_backup::log_follow() {
  journalctl --user -u "remote-repositories-backup.service" --since today --follow || fail
}
