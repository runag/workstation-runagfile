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

workstation::backup_my_github_repositories() {
  local backup_path="${HOME}/my/my-github-backup"

  local github_access_token; github_access_token="$(pass::use "${MY_GITHUB_ACCESS_TOKEN_PATH}")" || fail

  local fail_flag; fail_flag="$(mktemp -u)" || fail

  local full_name
  local git_url

  # NOTE: There is a 100 000 (1000*100) repository limit here. I put it here to not suffer an infinite loop if something is wrong
  local page_number_limit=1000

  if [ -t 0 ]; then # stdin is a terminal
    local fail_command="fail"
  else
    local fail_command="true"
  fi

  dir::make_if_not_exists "${backup_path}" || fail
  
  local page_number; for ((page_number=1; page_number<=page_number_limit; page_number++)); do
    # url for public repos for the specific user "https://api.github.com/users/${MY_GITHUB_LOGIN}/repos?page=${page_number}&per_page=100"
    curl \
      --fail \
      --retry 10 \
      --retry-connrefused \
      --show-error \
      --silent \
      --url "https://api.github.com/user/repos?page=${page_number}&per_page=100&visibility=all" \
      --user "${MY_GITHUB_LOGIN}:${github_access_token}" |\
    jq '.[] | [.full_name, .html_url] | @tsv' --raw-output --exit-status |\
    while IFS=$'\t' read -r full_name git_url; do
      log::notice "Backing up ${full_name}..." || fail
      git::place_up_to_date_clone "${git_url}" "${backup_path}/${full_name}" || { touch "${fail_flag}"; "${fail_command}"; }
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
