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


### Checksums
workstation::key_storage::checksum() {
  local action="$1"
  local path="${2:-"."}"
  local checksum_file="${3:-"checksums.txt"}"

  fs::with_secure_temp_dir_if_available "checksum::${action}" "${path}" "${checksum_file}" || fail
}

workstation::key_storage::maintain_checksums() {
  local skip_backups=false
  local checksum_action="checksum::create_or_update"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -s|--skip-backups)
        skip_backups=true
        shift
        ;;
      -v|--verify-only)
        checksum_action="checksum::verify"
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
      fs::with_secure_temp_dir_if_available "${checksum_action}" "${dir}" "checksums.txt" || fail
    fi
  done

  if [ "${skip_backups}" = true ]; then
    return
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
  gpg::import_key --confirm --skip-if-exists --trust-ultimately --secret-key "${gpg_key_id}" "${gpg_key_file}" || fail
}
