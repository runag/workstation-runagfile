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


# one command to encompass the whole workstation deployment process.
workstation::linux::deploy_workstation() {
  local key_storage_volume="/media/${USER}/workstation-sync"

  # install packages & configure
  workstation::linux::install_packages || fail
  workstation::linux::configure || fail

  # install gpg keys
  workstation::key_storage::maintain_checksums "${key_storage_volume}" || fail

  if ! workstation::get_flag "initial-gpg-keys-imported"; then
    local gpg_key_path; for gpg_key_path in "${key_storage_volume}/keys/workstation/gpg"/* ; do
      if [ -d "${gpg_key_path}" ]; then
        local gpg_key_id; gpg_key_id="$(basename "${gpg_key_path}")" || fail
        workstation::key_storage::import_gpg_key "${gpg_key_id}" "${gpg_key_path}/secret-subkeys.asc" || fail
      fi
    done
    workstation::set_flag "initial-gpg-keys-imported" || fail
  fi

  # install password store
  workstation::key_storage::clone_password_store_git_remote_to_local keys/workstation "${key_storage_volume}/keys/workstation/password-store" || fail
  workstation::key_storage::create_or_update_password_store_checksum || fail

  # install identities & credentials
  if ! workstation::get_flag "initial-identities-imported"; then
    local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"
    local absolute_identity_path; for absolute_identity_path in "${password_store_dir}/identity"/* ; do
      if [ -d "${absolute_identity_path}" ]; then
        local identity_path="${absolute_identity_path:$((${#password_store_dir}+1))}"
        workstation::use_identity --confirm --as-needed "${identity_path}" || fail
      fi
    done
    workstation::set_flag "initial-identities-imported" || fail
  fi

  # setup tailscale
  workstation::linux::deploy_tailscale tailscale/personal || fail

  # setup backup
  workstation::backup::credentials::deploy_remote backup/remotes/personal-backup-server || fail
  workstation::backup::credentials::deploy_profile backup/profiles/workstation || fail
  workstation::backup --each-repository create || softfail "workstation::backup --each-repository create failed"
  workstation::backup::services::deploy || fail

  # setup repositories backup
  if linux::is_bare_metal; then
    if ! workstation::get_flag "initial-remote-repository-credentials-imported"; then
      local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"
      local absolute_identity_path; for absolute_identity_path in "${password_store_dir}/identity"/* ; do
        if [ -d "${absolute_identity_path}/github" ]; then
          local identity_path="${absolute_identity_path:$((${#password_store_dir}+1))}"

          workstation::remote_repositories_backup::deploy_credentials --confirm "${identity_path}" || fail
        fi
      done
      workstation::set_flag "initial-remote-repository-credentials-imported" || fail
    fi
    workstation::remote_repositories_backup::create || softfail "workstation::remote_repositories_backup::create failed"
    workstation::remote_repositories_backup::deploy_services || fail
  fi
}
