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

workstation::backup::credentials::deploy_remote() {
  local remote_pass_path="$1"
  local remote_name; remote_name="${2:-"$(basename "${remote_pass_path}")"}" || fail

  local config_dir; config_dir="$(workstation::get_config_path "workstation-backup")" || fail

  if ! pass::dir_exists "${remote_pass_path}"; then
    fail "Remote not found: ${remote_pass_path}"
  fi

  local remote_config_dir="${config_dir}/remotes/${remote_name}"

  dir::should_exists --mode 0700 "${config_dir}" || fail
  dir::should_exists --mode 0700 "${config_dir}/remotes" || fail
  dir::should_exists --mode 0700 "${remote_config_dir}" || fail

  local remote_type; remote_type="$(pass::use "${remote_pass_path}/type")" || fail
  <<<"${remote_type}" file::write --mode 0600 "${remote_config_dir}/type" || fail

  if [ "${remote_type}" = ssh ]; then # install ssh profile
    ssh::add_ssh_config_d_include_directive || fail
    ssh::install_ssh_profile_from_pass --profile-name "workstation-backup-${remote_name}" "${remote_pass_path}" || fail
  else
    fail "Unknown remote type"
  fi
}

workstation::backup::credentials::deploy_profile() {(
  local profile_pass_path="$1"
  local profile_name; profile_name="${2:-"$(basename "${profile_pass_path}")"}" || fail

  local config_dir; config_dir="$(workstation::get_config_path "workstation-backup")" || fail

  if ! pass::dir_exists "${profile_pass_path}"; then
    fail "Profile not found: ${profile_pass_path}"
  fi

  local profile_config_path="${config_dir}/profiles/${profile_name}"

  dir::should_exists --mode 0700 "${config_dir}" || fail
  dir::should_exists --mode 0700 "${config_dir}/profiles" || fail
  dir::should_exists --mode 0700 "${profile_config_path}" || fail

  # install restic config
  dir::should_exists --mode 0700 "${profile_config_path}/passwords" || fail
  dir::should_exists --mode 0700 "${profile_config_path}/repositories" || fail

  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  cd "${password_store_dir}" || fail

  if pass::secret_exists "${profile_pass_path}/password"; then
    pass::use "${profile_pass_path}/password" file::write --mode 0600 "${profile_config_path}/passwords/default" || fail
  fi

  local secret_item; for secret_item in "${profile_pass_path}/passwords"/*.gpg; do
    if [ -f "${secret_item}" ]; then
      local secret_name; secret_name="$(basename "${secret_item}" .gpg)" || fail
      pass::use "${profile_pass_path}/passwords/${secret_name}" file::write --mode 0600 "${profile_config_path}/passwords/${secret_name}" || fail
    fi
  done

  if pass::secret_exists "${profile_pass_path}/repository"; then
    pass::use "${profile_pass_path}/repository" file::write --mode 0600 "${profile_config_path}/repositories/default" || fail
  fi

  local secret_item; for secret_item in "${profile_pass_path}/repositories"/*.gpg; do
    if [ -f "${secret_item}" ]; then
      local secret_name; secret_name="$(basename "${secret_item}" .gpg)" || fail

      local repository_string; repository_string="$(pass::use "${profile_pass_path}/repositories/${secret_name}")" || fail
    
      # shellcheck disable=2016
      repository_string="${repository_string//'${USER}'/"${USER}"}" || fail

      <<<"${repository_string}" file::write --mode 0600 "${profile_config_path}/repositories/${secret_name}" || fail
    fi
  done
)}
