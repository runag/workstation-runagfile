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

workstation::identity::runagfile_menu() {
  runagfile_menu::add --header "Configure identity and install credentials for use in project that resides in current directory: ${PWD}" || fail
  if [ -d .git ] || [ -f package.json ] || [ -f Gemfile ]; then
    workstation::identity::runagfile_menu::list || fail
  else
    runagfile_menu::add --note "No project found in current directory" || fail
  fi

  runagfile_menu::add --header "Configure identity and install credentials that could be used as needed for current user: ${USER}" || fail
  workstation::identity::runagfile_menu::list --as-needed || fail

  runagfile_menu::add --header "Configure identity and install credentials as a default for current user: ${USER}" || fail
  workstation::identity::runagfile_menu::list --as-default || fail
}

workstation::identity::runagfile_menu::list() {
  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  local identity_found=false

  local absolute_identity_path; for absolute_identity_path in "${password_store_dir}/identity"/* ; do
    if [ -d "${absolute_identity_path}" ]; then
      local identity_path="${absolute_identity_path:$((${#password_store_dir}+1))}"
      local git_user_name=""

      if pass::exists "${identity_path}/git/user-name"; then
        git_user_name="$(pass::use "${identity_path}/git/user-name")" || fail
      fi

      identity_found=true

      runagfile_menu::add ${git_user_name:+"--comment" "${git_user_name}"} workstation::use_identity "$@" "${identity_path}" || fail
    fi
  done

  if [ "${identity_found}" = false ]; then
    runagfile_menu::add --note "No identities found in password store" || fail
  fi
}
