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

workstation::remote_repositories_backup::menu() {
  # shellcheck disable=2119
  workstation::remote_repositories_backup::menu::identities || fail

  menu::add --header "Remote repositories backup: deploy" || fail

  menu::add workstation::remote_repositories_backup::initial_deploy || fail
  menu::add workstation::remote_repositories_backup::deploy_services || fail
  menu::add workstation::remote_repositories_backup::create || fail

  menu::add --header "Remote repositories backup: services" || fail

  menu::add workstation::remote_repositories_backup::start || fail
  menu::add workstation::remote_repositories_backup::stop || fail
  menu::add workstation::remote_repositories_backup::disable_timers || fail
  menu::add workstation::remote_repositories_backup::status || fail
  menu::add workstation::remote_repositories_backup::log || fail
  menu::add workstation::remote_repositories_backup::log_follow || fail
}

# shellcheck disable=2120
workstation::remote_repositories_backup::menu::identities() {
  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  menu::add --header "Remote repositories backup: deploy credentials" || fail

  local identity_found=false

  local absolute_identity_path; for absolute_identity_path in "${password_store_dir}/identity"/* ; do
    if [ -d "${absolute_identity_path}" ] && \
       [ -f "${absolute_identity_path}/github/personal-access-token.gpg" ] && \
       [ -f "${absolute_identity_path}/github/username.gpg" ]; then
      local identity_path="${absolute_identity_path:$((${#password_store_dir}+1))}"
      local github_username; github_username="$(pass::use "${identity_path}/github/username")" || fail

      identity_found=true
      menu::add --comment "github:${github_username}" workstation::remote_repositories_backup::deploy_credentials "$@" "${identity_path}" || fail
    fi
  done

  if [ "${identity_found}" = false ]; then
    menu::add --note "Unable to find any identity" || fail
  fi
}

workstation::remote_repositories_backup::initial_deploy() {
  if ! workstation::get_flag "remote-repositories-backup-was-suggested"; then
    if ui::confirm "Do you want to store remote repositories backup on this machine?"; then
      workstation::set_flag "remote-repositories-backup-was-accepted" || fail
    else
      workstation::set_flag "remote-repositories-backup-was-rejected" || fail
    fi
    workstation::set_flag "remote-repositories-backup-was-suggested" || fail
  fi

  if workstation::get_flag "remote-repositories-backup-was-rejected"; then
    log::warning "Remote repositories backup will not be stored on this machine" || fail
    return 0
  fi

  if ! workstation::get_flag "remote-repositories-backup-was-accepted"; then
    fail "Unreachable state reached"
  fi

  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"
  local absolute_identity_path; for absolute_identity_path in "${password_store_dir}/identity"/* ; do
    if [ -d "${absolute_identity_path}/github" ]; then
      local identity_path="${absolute_identity_path:$((${#password_store_dir}+1))}"

      workstation::remote_repositories_backup::deploy_credentials "${identity_path}" || fail
    fi
  done

  # workstation::remote_repositories_backup::create || softfail "workstation::remote_repositories_backup::create failed"
  workstation::remote_repositories_backup::deploy_services || fail
}

workstation::remote_repositories_backup::deploy_credentials() {
  local should_confirm=false

  while [ "$#" -gt 0 ]; do
    case "$1" in
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

  if [ "${should_confirm}" = true ]; then
    echo ""
    echo "You are about to import credentials \"${credentials_name}\" from: ${credentials_path}"
    echo ""
    echo "Please confirm that it is your intention to do so by entering \"yes\""
    echo "Please prepare the password if needed"
    echo "Please enter \"no\" if you want to continue without them being imported."

    if ! ui::confirm; then
      log::warning "Credentials were not imported" || fail
      return 0
    fi
  fi

  local config_dir; config_dir="$(workstation::get_config_path "remote-repositories-backup")" || fail

  dir::should_exists --mode 0700 "${config_dir}" || fail
  dir::should_exists --mode 0700 "${config_dir}/github" || fail
  dir::should_exists --mode 0700 "${config_dir}/github/${credentials_name}" || fail

  pass::use "${credentials_path}/github/username" file::write --mode 0600 "${config_dir}/github/${credentials_name}/username" || fail
  pass::use "${credentials_path}/github/personal-access-token" file::write --mode 0600 "${config_dir}/github/${credentials_name}/personal-access-token" || fail
}

# shellcheck disable=2030
workstation::remote_repositories_backup::create() {
  local backups_home="${HOME}/backups"

  dir::should_exists --mode 0700 "${backups_home}" || fail

  local backup_path="${backups_home}/remote-repositories"

  dir::should_exists --mode 0700 "${backup_path}" || fail
  dir::should_exists --mode 0700 "${backup_path}/github" || fail

  local config_dir; config_dir="$(workstation::get_config_path "remote-repositories-backup")" || fail

  local exit_status=0

  local credentials_path; for credentials_path in "${config_dir}/github"/*; do
    if [ -d "${credentials_path}" ]; then
      local credentials_name; credentials_name="$(basename "${credentials_path}")" || fail

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

  dir::should_exists --mode 0700 "${backup_path}" || fail

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
    jq --raw-output --exit-status '.[] | [.full_name, .html_url] | @tsv' |\
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
      return 0
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
  journalctl --user -u "remote-repositories-backup.service" --lines 2048 || fail
}

workstation::remote_repositories_backup::log_follow() {
  journalctl --user -u "remote-repositories-backup.service" --lines 2048 --follow || fail
}
