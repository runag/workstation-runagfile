#!/usr/bin/env bash

#  Copyright 2012-2022 Rùnag project contributors
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

workstation::remote_repositories_backup::runagfile_menu() {
  workstation::remote_repositories_backup::runagfile_menu::identities || fail

  runagfile_menu::add --header "Remote repositories backup: deploy" || fail

  runagfile_menu::add workstation::remote_repositories_backup::deploy_services || fail
  runagfile_menu::add workstation::remote_repositories_backup::create || fail

  runagfile_menu::add --header "Remote repositories backup: services" || fail

  runagfile_menu::add workstation::remote_repositories_backup::start || fail
  runagfile_menu::add workstation::remote_repositories_backup::stop || fail
  runagfile_menu::add workstation::remote_repositories_backup::disable_timers || fail
  runagfile_menu::add workstation::remote_repositories_backup::status || fail
  runagfile_menu::add workstation::remote_repositories_backup::log || fail
  runagfile_menu::add workstation::remote_repositories_backup::log_follow || fail
}

workstation::remote_repositories_backup::runagfile_menu::identities() {
  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  runagfile_menu::add --header "Remote repositories backup: deploy credentials" || fail

  local identity_found=false

  local absolute_identity_path; for absolute_identity_path in "${password_store_dir}/identity"/* ; do
    if [ -d "${absolute_identity_path}" ] && \
       [ -f "${absolute_identity_path}/github/personal-access-token.gpg" ] && \
       [ -f "${absolute_identity_path}/github/username.gpg" ]; then
      local identity_path="${absolute_identity_path:$((${#password_store_dir}+1))}"
      local github_username; github_username="$(pass::use "${identity_path}/github/username")" || fail

      runagfile_menu::add --comment "github:${github_username}" workstation::remote_repositories_backup::deploy_credentials "$@" "${identity_path}" || fail

      identity_found=true
    fi
  done

  if [ "${identity_found}" = false ]; then
    runagfile_menu::add --note "Unable to find any identity" || fail
  fi
}

workstation::remote_repositories_backup::deploy_credentials() {
  local should_confirm

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -c|--confirm)
        should_confirm=true
        shift
        ;;
      -*)
        fail "Unknown argument: $1"
        ;;
      *)
        break
        ;;
    esac
  done

  local credentials_path="$1"
  local credentials_name; credentials_name="${2:-"$(basename "${credentials_path}")"}" || fail

  if [ "${should_confirm:-}" = true ]; then
    echo "You are about to import credentials \"${credentials_name}\" from: ${credentials_path}"

    echo "Please confirm that it is your intention to do so by entering \"yes\""
    echo "Please prepare the password if needed"
    echo "Please enter \"no\" if you want to continue without them being imported."

    local action; IFS="" read -r action || fail

    if [ "${action}" = no ]; then
      echo "Credentials are ignored"
      return
    fi

    if [ "${action}" != yes ]; then
      fail
    fi
  fi

  local config_dir="${HOME}/.remote-repositories-backup"

  dir::make_if_not_exists_and_set_permissions "${config_dir}" 0700 || fail
  dir::make_if_not_exists_and_set_permissions "${config_dir}/github" 0700 || fail
  dir::make_if_not_exists_and_set_permissions "${config_dir}/github/${credentials_name}" 0700 || fail

  pass::use "${credentials_path}/github/username" file::write --mode 0600 "${config_dir}/github/${credentials_name}/username" || fail
  pass::use "${credentials_path}/github/personal-access-token" file::write --mode 0600 "${config_dir}/github/${credentials_name}/personal-access-token" || fail
}

# shellcheck disable=2030
workstation::remote_repositories_backup::create() {
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

      workstation::remote_repositories_backup::backup_github_repositories "${backup_path}/github/${credentials_name}" || exit_status=1
    fi
  done

  if [ "${exit_status}" != 0 ]; then
    fail
  fi
}

# shellcheck disable=2031
workstation::remote_repositories_backup::backup_github_repositories() {
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
      git::create_or_update_mirror "https://${GITHUB_USERNAME}@${git_url:8}" "${backup_path}/${full_name}" || touch "${fail_flag}"
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

workstation::remote_repositories_backup::deploy_services() {
  systemd::write_user_unit "remote-repositories-backup.service" <<EOF || fail
[Unit]
Description=Remote repositories backup

[Service]
Type=oneshot
ExecStart=${RUNAG_BIN_PATH} workstation::remote_repositories_backup::create
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

workstation::remote_repositories_backup::start() {
  systemctl --user --no-block start "remote-repositories-backup.service" || fail
}

workstation::remote_repositories_backup::stop() {
  systemctl --user stop "remote-repositories-backup.service" || fail
}

workstation::remote_repositories_backup::disable_timers() {
  systemctl --user stop "remote-repositories-backup.timer" || fail
  systemctl --user --quiet disable "remote-repositories-backup.timer" || fail
}

workstation::remote_repositories_backup::status() {
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

workstation::remote_repositories_backup::log() {
  journalctl --user -u "remote-repositories-backup.service" --since today || fail
}

workstation::remote_repositories_backup::log_follow() {
  journalctl --user -u "remote-repositories-backup.service" --since today --follow || fail
}
