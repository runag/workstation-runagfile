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

workstation::repositories_backup::tasks::set() {
  # shellcheck disable=2119
  workstation::repositories_backup::tasks::identities || fail

  # Repositories backup: deploy (task header)

  task::add workstation::repositories_backup::deploy || softfail || return $?
  task::add workstation::repositories_backup::deploy_services || softfail || return $?
  task::add workstation::repositories_backup::create || softfail || return $?

  systemd::service_tasks --user --with-timer --service-name "repositories-backup" || softfail || return $?
}

task::add --group workstation::repositories_backup::tasks || softfail || return $?

# shellcheck disable=2120
workstation::repositories_backup::tasks::identities() {
  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  # Repositories backup: deploy credentials (task header)

  local identity_found=false

  local absolute_identity_path; for absolute_identity_path in "${password_store_dir}/identity"/* ; do
    if [ -d "${absolute_identity_path}" ] && \
       [ -f "${absolute_identity_path}/github/personal-access-token.gpg" ] && \
       [ -f "${absolute_identity_path}/github/username.gpg" ]; then
      local identity_path="${absolute_identity_path:$((${#password_store_dir}+1))}"
      local github_username; github_username="$(pass::use "${identity_path}/github/username")" || fail

      task::add --comment "github:${github_username}" workstation::repositories_backup::deploy_credentials "$@" "${identity_path}" || softfail || return $?

      identity_found=true
    fi
  done

  if [ "${identity_found}" = false ]; then
    # Unable to find any identity (task note)
    true
  fi
}

workstation::repositories_backup::deploy() {
  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"
  local absolute_identity_path; for absolute_identity_path in "${password_store_dir}/identity"/* ; do
    if [ -d "${absolute_identity_path}/github" ]; then
      local identity_path="${absolute_identity_path:$((${#password_store_dir}+1))}"

      workstation::repositories_backup::deploy_credentials "${identity_path}" || fail
    fi
  done

  workstation::repositories_backup::deploy_services || fail
}

workstation::repositories_backup::deploy_credentials() {
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

  local config_dir; config_dir="$(workstation::get_config_dir "repositories-backup/github/${credentials_name}")" || fail

  pass::use "${credentials_path}/github/username" file::write --user-only "${config_dir}/username" || fail
  pass::use "${credentials_path}/github/personal-access-token" file::write --user-only "${config_dir}/personal-access-token" || fail
}

# shellcheck disable=2030
workstation::repositories_backup::create() {
  local data_home="${XDG_DATA_HOME:-"${HOME}/.local/share"}"
  ( umask 0077 && mkdir -p "${data_home}" ) || fail

  local backup_path="${data_home}/repositories-backup"

  dir::ensure_exists --mode 0700 "${backup_path}" || fail
  dir::ensure_exists --mode 0700 "${backup_path}/github" || fail

  local config_dir; config_dir="$(workstation::get_config_dir "repositories-backup/github")" || fail

  local exit_status=0

  local credentials_path; for credentials_path in "${config_dir}"/*; do
    if [ -d "${credentials_path}" ]; then
      local credentials_name; credentials_name="$(basename "${credentials_path}")" || fail

      local GITHUB_USERNAME; GITHUB_USERNAME="$(<"${credentials_path}"/username)"
      local GITHUB_PERSONAL_ACCESS_TOKEN; GITHUB_PERSONAL_ACCESS_TOKEN="$(<"${credentials_path}"/personal-access-token)"

      workstation::repositories_backup::backup_github_repositories "${backup_path}/github/${credentials_name}" || exit_status=1
    fi
  done

  if [ "${exit_status}" != 0 ]; then
    fail
  fi
}

# shellcheck disable=2031
workstation::repositories_backup::backup_github_repositories() {
  local backup_path="$1"

  # NOTE: There is a 10 000 (100*100) repository limit here. I put it here to not suffer an infinite loop if something is wrong
  local page_number_limit=100

  local full_name git_url

  local fail_flag; fail_flag="$(mktemp -u)" || fail

  dir::ensure_exists --mode 0700 "${backup_path}" || fail

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

workstation::repositories_backup::deploy_services() {
  local runag_path; runag_path="$(command -v runag)" || fail

  systemd::write_user_unit "repositories-backup.service" <<EOF || fail
[Unit]
Description=Repositories backup

[Service]
Type=oneshot
ExecStart=${runag_path} workstation::repositories_backup::create
SyslogIdentifier=repositories-backup
ProtectSystem=full
PrivateTmp=true
NoNewPrivileges=true
EOF

  systemd::write_user_unit "repositories-backup.timer" <<EOF || fail
[Unit]
Description=Timer for Repositories backup

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=600

[Install]
WantedBy=timers.target
EOF

  # enable the service and start the timer
  systemctl --user --quiet reenable "repositories-backup.timer" || fail
  systemctl --user start "repositories-backup.timer" || fail
}
