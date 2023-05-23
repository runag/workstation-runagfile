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

workstation::key_storage::runagfile_menu() {

  runagfile_menu::add --header "Local key and password storage: ${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}" || fail

  if [ -d "${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}" ]; then
    runagfile_menu::add workstation::key_storage::password_store_checksum create_or_update || fail
    runagfile_menu::add workstation::key_storage::password_store_checksum verify || fail
  else
    runagfile_menu::add --note "Unable to find local key and password storage" || fail
  fi


  runagfile_menu::add --header "Checksums for current directory: ${PWD}" || fail

  if [ -f "checksums.txt" ]; then
    runagfile_menu::add fs::with_secure_temp_dir_if_available checksums::create_or_update "." "checksums.txt" || fail
    runagfile_menu::add fs::with_secure_temp_dir_if_available checksums::verify "." "checksums.txt" || fail
  else
    runagfile_menu::add --note "There are no checksums.txt file in current directory" || fail
  fi

  local key_storage_found=false

  if [[ "${OSTYPE}" =~ ^msys ]]; then
    workstation::key_storage::runagfile_menu::media /? || fail

  elif [[ "${OSTYPE}" =~ ^darwin ]]; then
    local media_path; for media_path in "/Volumes"/* ; do
      if [ -d "${media_path}" ]; then
        workstation::key_storage::runagfile_menu::media "${media_path}" || fail
      fi
    done

  elif [[ "${OSTYPE}" =~ ^linux ]]; then
    local media_path; for media_path in "/media/${USER}"/* ; do
      if [ -d "${media_path}" ]; then
        workstation::key_storage::runagfile_menu::media "${media_path}" || fail
      fi
    done

  fi

  workstation::key_storage::runagfile_menu::media "." || fail

  if [ "${key_storage_found}" = false ]; then
    runagfile_menu::add --header "Key storage" || fail
    runagfile_menu::add --note "No key storage found" || fail
  fi
}

workstation::key_storage::runagfile_menu::media() {
  local media_path="$1"

  if [ ! -d "${media_path}/keys" ]; then
    return 0
  fi

  key_storage_found=true

  runagfile_menu::add --header "Key storage: ${media_path}" || fail
  
  # Checksums
  runagfile_menu::add workstation::key_storage::maintain_checksums "${media_path}" || fail
  runagfile_menu::add workstation::key_storage::make_backups "${media_path}" || fail


  local scope_found=false

  # Scopes
  local scope_path; for scope_path in "${media_path}/keys"/* ; do
    if [ -d "${scope_path}" ] && [ ! -f "${scope_path}/.exclude-from-menu" ]; then

      local media_name; media_name="$(basename "${media_path}")" || fail
      local scope_name; scope_name="$(basename "${scope_path}")" || fail
      local git_remote_name="${media_name}/${scope_name}"

      scope_found=true

      runagfile_menu::add --subheader "Password store in: ${media_path}/${scope_name}" || fail
      workstation::key_storage::runagfile_menu::password_store "${scope_path}" "${git_remote_name}" || fail

      runagfile_menu::add --subheader "GPG keys in: ${media_path}/${scope_name}" || fail
      workstation::key_storage::runagfile_menu::gpg_keys "${scope_path}" || fail
    fi
  done

  if [ "${scope_found}" = false ]; then
    runagfile_menu::add --note "No key storage scopes found" || fail
  fi
}

workstation::key_storage::runagfile_menu::password_store() {
  local scope_path="$1"
  local git_remote_name="$2"

  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  local password_store_git_remote_path="${scope_path}/password-store"

  if [ -d "${password_store_dir}/.git" ]; then
    if [ -d "${password_store_git_remote_path}" ]; then
      runagfile_menu::add workstation::key_storage::add_or_update_password_store_git_remote "${git_remote_name}" "${password_store_git_remote_path}" || fail
    else
      runagfile_menu::add workstation::key_storage::create_password_store_git_remote "${git_remote_name}" "${password_store_git_remote_path}" || fail
    fi
  else
    runagfile_menu::add --note "No local password store with git versioning found: ${password_store_dir}/.git" || fail
  fi

  if [ -d "${password_store_git_remote_path}" ]; then
    if [ ! -d "${password_store_dir}" ]; then
      runagfile_menu::add workstation::key_storage::password_store_git_remote_clone_or_update_to_local "${git_remote_name}" "${password_store_git_remote_path}" || fail
    else
      runagfile_menu::add --note "There is no need to clone password store git remote as local password store already exists: ${password_store_dir}" || fail
    fi
  else
    runagfile_menu::add --note "Password store git remote not exists: ${password_store_git_remote_path}" || fail
  fi
}

workstation::key_storage::runagfile_menu::gpg_keys() {
  local scope_path="$1"

  local gpg_keys_path="${scope_path}/gpg"

  local gpg_keys_found=false

  local gpg_key_dir; for gpg_key_dir in "${gpg_keys_path}"/* ; do
    if [ -d "${gpg_key_dir}" ]; then
      local gpg_key_id; gpg_key_id="$(basename "${gpg_key_dir}")" || fail
      local gpg_key_file="${gpg_key_dir}/secret-subkeys.asc"
      local gpg_public_key_file="${gpg_key_dir}/public.asc"
      local gpg_key_uid=""

      if [ -f "${gpg_public_key_file}" ]; then
        gpg_key_uid="$(gpg::get_key_uid "${gpg_public_key_file}")" || fail
      fi

      if [ -f "${gpg_key_file}" ]; then
        gpg_keys_found=true
        runagfile_menu::add ${gpg_key_uid:+"--comment" "${gpg_key_uid}"} workstation::key_storage::import_gpg_key "${gpg_key_id}" "${gpg_key_file}" || fail
      fi
    fi
  done

  if [ "${gpg_keys_found}" = false ]; then
    runagfile_menu::add --note "No GPG keys found" || fail
  fi
}
