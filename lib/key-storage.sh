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

task::add --group workstation::key_storage::tasks || softfail || return $?

workstation::key_storage::tasks::set() {
  # Checksums for current directory: ${PWD} (task header)

  if [ -f "checksums.txt" ]; then
    task::add --comment "Checksums for current directory: ${PWD}" workstation::key_storage::checksum create_or_update || softfail || return $?
    task::add --comment "Checksums for current directory: ${PWD}" workstation::key_storage::checksum verify || softfail || return $?
  else
    # There are no checksums.txt file in current directory (task note)
    task::add --comment "Checksums for current directory: ${PWD}" workstation::key_storage::checksum create_or_update || softfail || return $?
  fi

  local Key_Storage_Found=false

  if [[ "${OSTYPE}" =~ ^darwin ]]; then
    local media_path; for media_path in "/Volumes"/* ; do
      if [ -d "${media_path}" ]; then
        workstation::key_storage::tasks::media "${media_path}" || softfail || return $?
      fi
    done

  elif [[ "${OSTYPE}" =~ ^linux ]]; then
    local mounts_path; mounts_path="$(linux::user_media_path)" || softfail || return $?

    local media_path; for media_path in "${mounts_path}"/* ; do
      if [ -d "${media_path}" ]; then
        workstation::key_storage::tasks::media "${media_path}" || softfail || return $?
      fi
    done

  fi

  workstation::key_storage::tasks::media "." || softfail || return $?

  if [ "${Key_Storage_Found}" = false ]; then
    # Key storage (task header)
    # No key storage found (task note)
    true
  fi
}

workstation::key_storage::tasks::media() {
  local media_path="$1"

  if [ ! -d "${media_path}/keys" ]; then
    return 0
  fi

  Key_Storage_Found=true

  # Key storage: ${media_path} (task header)
  
  # Scopes
  local scope_found=false

  local scope_path; for scope_path in "${media_path}/keys"/* ; do
    if [ -d "${scope_path}" ] && [ ! -f "${scope_path}/.exclude-from-tasks" ]; then

      local media_name; media_name="$(basename "${media_path}")" || softfail || return $?
      local scope_name; scope_name="$(basename "${scope_path}")" || softfail || return $?
      local git_remote_name="${media_name}/${scope_name}"

      scope_found=true

      # Password store in: ${media_path}/${scope_name} (task header)
      workstation::key_storage::tasks::password_store "${scope_path}" "${git_remote_name}" || softfail || return $?

      # GPG keys in: ${media_path}/${scope_name} (task header)
      workstation::key_storage::tasks::gpg_keys "${scope_path}" || softfail || return $?
    fi
  done

  if [ "${scope_found}" = false ]; then
    # No key storage scopes found (task note)
    true
  fi

  # Checksums
  # Checksums for: ${media_path} (task header)
  task::add workstation::key_storage::maintain_checksums "${media_path}" || softfail || return $?
  task::add workstation::key_storage::make_backups "${media_path}" || softfail || return $?
}

workstation::key_storage::tasks::password_store() {
  local scope_path="$1"
  local git_remote_name="$2"

  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  local password_store_git_remote_path="${scope_path}/password-store"

  if [ -d "${password_store_dir}/.git" ]; then
    if [ -d "${password_store_git_remote_path}" ]; then
      task::add workstation::key_storage::add_or_update_password_store_git_remote "${git_remote_name}" "${password_store_git_remote_path}" || softfail || return $?
    else
      task::add workstation::key_storage::create_password_store_git_remote "${git_remote_name}" "${password_store_git_remote_path}" || softfail || return $?
    fi
  else
    # No local password store with git versioning found: ${password_store_dir}/.git (task note)
    true
  fi

  if [ -d "${password_store_git_remote_path}" ]; then
    if [ ! -d "${password_store_dir}" ]; then
      task::add workstation::key_storage::password_store_git_remote_clone_or_update_to_local "${git_remote_name}" "${password_store_git_remote_path}" || softfail || return $?
    else
      # There is no need to clone password store git remote as local password store already exists: ${password_store_dir} (task note)
      true
    fi
  else
    # Password store git remote not exists: ${password_store_git_remote_path} (task note)
    true
  fi
}

workstation::key_storage::tasks::gpg_keys() {
  local scope_path="$1"

  local gpg_keys_path="${scope_path}/gpg"

  local gpg_keys_found=false

  local gpg_key_dir; for gpg_key_dir in "${gpg_keys_path}"/* ; do
    if [ -d "${gpg_key_dir}" ]; then
      local gpg_key_id; gpg_key_id="$(basename "${gpg_key_dir}")" || softfail || return $?
      local gpg_key_file="${gpg_key_dir}/secret-subkeys.asc"
      local gpg_public_key_file="${gpg_key_dir}/public.asc"
      local gpg_key_uid

      if [ -f "${gpg_public_key_file}" ]; then
        gpg_key_uid="$(gpg::get_key_uid "${gpg_public_key_file}")" || softfail || return $?
      fi

      if [ -f "${gpg_key_file}" ]; then
        gpg_keys_found=true
        task::add ${gpg_key_uid:+"--comment" "${gpg_key_uid}"} workstation::key_storage::import_gpg_key "${gpg_key_id}" "${gpg_key_file}" || softfail || return $?
      fi
    fi
  done

  if [ "${gpg_keys_found}" = false ]; then
    # No GPG keys found (task note)
    true
  fi
}


### Checksums
workstation::key_storage::checksum() {
  local action="$1"
  local path="${2:-"."}"
  local checksum_file="${3:-"checksums.txt"}"

  fs::with_secure_temp_dir_if_available "checksum::${action}" "${path}" "${checksum_file}" || fail
}

workstation::key_storage::maintain_checksums() {
  local skip_backups=false
  local checksum_action="create_or_update"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -s|--skip-backups)
        skip_backups=true
        shift
        ;;
      -v|--verify-only)
        checksum_action="verify"
        shift
        ;;
      -*)
        softfail "Unknown argument: $1" || return $?
        ;;
      *)
        break
        ;;
    esac
  done
  
  local media_path="$1"

  local dir; for dir in "${media_path}/keys/"* "${media_path}/keys/"*/*; do
    if [ -d "${dir}" ] && [ -f "${dir}/checksums.txt" ]; then
      fs::with_secure_temp_dir_if_available "checksum::${checksum_action}" "${dir}" "checksums.txt" || fail
    fi
  done

  if [ "${skip_backups}" = true ]; then
    return 0
  fi

  local dir; for dir in "${media_path}/keys-backup/"*; do
    if [ -d "${dir}" ] && [ -f "${dir}/checksums.txt" ]; then
      fs::with_secure_temp_dir_if_available checksum::verify "${dir}" "checksums.txt" || fail
    fi
  done
}

workstation::key_storage::make_backups() {
  local media_path="$1"

  workstation::key_storage::maintain_checksums --skip-backups "${media_path}" || fail

  local backups_dir="${media_path}/keys-backup"
  local dest_dir; dest_dir="${backups_dir}/$(date --utc +"%Y%m%dT%H%M%SZ")" || fail

  dir::should_exists --mode 0700 "${backups_dir}" || fail
  dir::should_exists --mode 0700 "${dest_dir}" || fail

  cp -R "${media_path}/keys" "${dest_dir}" || fail

  RUNAG_CREATE_CHECKSUMS_WITHOUT_CONFIRMATION=true fs::with_secure_temp_dir_if_available checksum::create_or_update "${dest_dir}" "checksums.txt" || fail

  sync || fail

  workstation::key_storage::maintain_checksums --skip-backups --verify-only "${dest_dir}" || fail

  echo "Backups were made: ${dest_dir}"
}


### Password store

workstation::key_storage::add_or_update_password_store_git_remote() {(
  local git_remote_name="$1"
  local password_store_git_remote_path="$2"

  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  cd "${password_store_dir}" || fail

  git::add_or_update_remote "${git_remote_name}" "${password_store_git_remote_path}" || fail
  git branch --move --force main || fail
  git push --set-upstream "${git_remote_name}" main || fail
)}

workstation::key_storage::create_password_store_git_remote() {
  local git_remote_name="$1"
  local password_store_git_remote_path="$2"

  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  git init --bare "${password_store_git_remote_path}" || fail

  workstation::key_storage::add_or_update_password_store_git_remote "${git_remote_name}" "${password_store_git_remote_path}" || fail
}

workstation::key_storage::password_store_git_remote_clone_or_update_to_local() {
  local git_remote_name="$1"
  local password_store_git_remote_path="$2"

  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  if [ ! -d "${password_store_dir}" ]; then
    ( umask 077 && git clone --origin "${git_remote_name}" "${password_store_git_remote_path}" "${password_store_dir}" ) || fail
  else
    (
      cd "${password_store_dir}" || fail

      # local remote case
      if git::is_remote_local "${git_remote_name}"; then
        if ! git::is_local_remote_connected "${git_remote_name}"; then
          log::warning "${git_remote_name} git remote in ${PWD} is not available by local protocol path" || fail
          return 0
        fi
      fi
      
      git pull "${git_remote_name}" main || fail
    ) || fail
  fi
}


### GPG keys

workstation::key_storage::import_gpg_key() {
  local gpg_key_id="$1"
  local gpg_key_file="$2"
  gpg::import_key --skip-if-exists --trust-ultimately --secret-key "${gpg_key_id}" "${gpg_key_file}" || fail
}
