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

workstation::key_storage::menu() {
  menu::add --header "Checksums for current directory: ${PWD}" || fail

  if [ -f "checksums.txt" ]; then
    menu::add workstation::key_storage::checksum create_or_update || fail
    menu::add workstation::key_storage::checksum verify || fail
  else
    menu::add workstation::key_storage::checksum create_or_update || fail
    menu::add --note "There are no checksums.txt file in current directory" || fail
  fi

  local Key_Storage_Found=false

  if [[ "${OSTYPE}" =~ ^msys ]]; then
    # TODO
    true

  elif [[ "${OSTYPE}" =~ ^darwin ]]; then
    local media_path; for media_path in "/Volumes"/* ; do
      if [ -d "${media_path}" ]; then
        workstation::key_storage::menu::media "${media_path}" || fail
      fi
    done

  elif [[ "${OSTYPE}" =~ ^linux ]]; then
    local media_path; for media_path in "/media/${USER}"/* ; do
      if [ -d "${media_path}" ]; then
        workstation::key_storage::menu::media "${media_path}" || fail
      fi
    done

  fi

  workstation::key_storage::menu::media "." || fail

  if [ "${Key_Storage_Found}" = false ]; then
    menu::add --header "Key storage" || fail
    menu::add --note "No key storage found" || fail
  fi
}

workstation::key_storage::menu::media() {
  local media_path="$1"

  if [ ! -d "${media_path}/keys" ]; then
    return 0
  fi

  Key_Storage_Found=true

  menu::add --header "Key storage: ${media_path}" || fail
  
  # Checksums
  menu::add workstation::key_storage::maintain_checksums "${media_path}" || fail
  menu::add workstation::key_storage::make_backups "${media_path}" || fail


  # Scopes
  local scope_found=false

  local scope_path; for scope_path in "${media_path}/keys"/* ; do
    if [ -d "${scope_path}" ] && [ ! -f "${scope_path}/.exclude-from-menu" ]; then

      local media_name; media_name="$(basename "${media_path}")" || fail
      local scope_name; scope_name="$(basename "${scope_path}")" || fail
      local git_remote_name="${media_name}/${scope_name}"

      scope_found=true

      menu::add --header "Password store in: ${media_path}/${scope_name}" || fail
      workstation::key_storage::menu::password_store "${scope_path}" "${git_remote_name}" || fail

      menu::add --header "GPG keys in: ${media_path}/${scope_name}" || fail
      workstation::key_storage::menu::gpg_keys "${scope_path}" || fail
    fi
  done

  if [ "${scope_found}" = false ]; then
    menu::add --note "No key storage scopes found" || fail
  fi
}

workstation::key_storage::menu::password_store() {
  local scope_path="$1"
  local git_remote_name="$2"

  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  local password_store_git_remote_path="${scope_path}/password-store"

  if [ -d "${password_store_dir}/.git" ]; then
    if [ -d "${password_store_git_remote_path}" ]; then
      menu::add workstation::key_storage::add_or_update_password_store_git_remote "${git_remote_name}" "${password_store_git_remote_path}" || fail
    else
      menu::add workstation::key_storage::create_password_store_git_remote "${git_remote_name}" "${password_store_git_remote_path}" || fail
    fi
  else
    menu::add --note "No local password store with git versioning found: ${password_store_dir}/.git" || fail
  fi

  if [ -d "${password_store_git_remote_path}" ]; then
    if [ ! -d "${password_store_dir}" ]; then
      menu::add workstation::key_storage::password_store_git_remote_clone_or_update_to_local "${git_remote_name}" "${password_store_git_remote_path}" || fail
    else
      menu::add --note "There is no need to clone password store git remote as local password store already exists: ${password_store_dir}" || fail
    fi
  else
    menu::add --note "Password store git remote not exists: ${password_store_git_remote_path}" || fail
  fi
}

workstation::key_storage::menu::gpg_keys() {
  local scope_path="$1"

  local gpg_keys_path="${scope_path}/gpg"

  local gpg_keys_found=false

  local gpg_key_dir; for gpg_key_dir in "${gpg_keys_path}"/* ; do
    if [ -d "${gpg_key_dir}" ]; then
      local gpg_key_id; gpg_key_id="$(basename "${gpg_key_dir}")" || fail
      local gpg_key_file="${gpg_key_dir}/secret-subkeys.asc"
      local gpg_public_key_file="${gpg_key_dir}/public.asc"
      local gpg_key_uid

      if [ -f "${gpg_public_key_file}" ]; then
        gpg_key_uid="$(gpg::get_key_uid "${gpg_public_key_file}")" || fail
      fi

      if [ -f "${gpg_key_file}" ]; then
        gpg_keys_found=true
        menu::add ${gpg_key_uid:+"--comment" "${gpg_key_uid}"} workstation::key_storage::import_gpg_key "${gpg_key_id}" "${gpg_key_file}" || fail
      fi
    fi
  done

  if [ "${gpg_keys_found}" = false ]; then
    menu::add --note "No GPG keys found" || fail
  fi
}
