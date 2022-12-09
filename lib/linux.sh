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

if runagfile_menu::necessary linux; then
  runagfile_menu::add_header "Linux workstation: complete deploy script" || fail

  runagfile_menu::add workstation::linux::deploy_workstation || fail

  runagfile_menu::add_header "Linux workstation: particular deployment tasks" || fail

  runagfile_menu::add workstation::linux::install_packages || fail
  runagfile_menu::add workstation::linux::configure || fail
  runagfile_menu::add workstation::linux::deploy_lan_server || fail
  runagfile_menu::add workstation::linux::deploy_tailscale tailscale/personal || fail
  
  if vmware::is_inside_vm; then
    runagfile_menu::add workstation::linux::deploy_vm_host_directory_mounts windows-cifs/personal || fail
  fi
fi

# one command to encompass the whole workstation deployment process.
workstation::linux::deploy_workstation() {
  local key_storage_volume="/media/${USER}/key-storage"

  # install packages & configure
  workstation::linux::install_packages || fail
  workstation::linux::configure || fail

  # install gpg keys
  workstation::key_storage::maintain_checksums "${key_storage_volume}" || fail

  local gpg_key_path; for gpg_key_path in "${key_storage_volume}/keys/workstation/gpg"/* ; do
    if [ -d "${gpg_key_path}" ]; then
      local gpg_key_id; gpg_key_id="$(basename "${gpg_key_path}")" || fail
      workstation::key_storage::import_gpg_key "${gpg_key_id}" "${gpg_key_path}/secret-subkeys.asc" || fail
    fi
  done

  # install password store
  workstation::key_storage::clone_password_store_git_remote_to_local key-storage/workstation "${key_storage_volume}/keys/workstation/password-store" || fail
  workstation::key_storage::create_or_update_password_store_checksum || fail

  # install identity
  workstation::use_identity identity/personal || fail

  # setup tailscale
  workstation::linux::deploy_tailscale tailscale/personal || fail

  # setup backup
  workstation::backup::credentials::deploy_remote backup/remotes/personal-backup-server || fail
  workstation::backup::credentials::deploy_profile backup/profiles/workstation || fail
  workstation::backup create || fail
  workstation::backup::services::deploy || fail

  # setup repositories backup
  if linux::is_bare_metal; then
    workstation::remote_repositories_backup::deploy_credentials identity/personal || fail
    workstation::remote_repositories_backup::create || fail
    workstation::remote_repositories_backup::deploy_services || fail
  fi
}
