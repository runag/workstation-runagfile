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

key_storage::populate_sopka_menu() {
  if [[ "${OSTYPE}" =~ ^msys ]]; then
    key_storage::add_sopka_menu_for_media "/k" || fail

  elif [[ "${OSTYPE}" =~ ^darwin ]]; then
    local media_path; for media_path in "/Volumes/"*KEYS* ; do
      if [ -d "${media_path}" ]; then
        key_storage::add_sopka_menu_for_media "${media_path}" || fail
      fi
    done

  elif [[ "${OSTYPE}" =~ ^linux ]]; then
    local media_path; for media_path in "/media/${USER}/"*KEYS* ; do
      if [ -d "${media_path}" ]; then
        key_storage::add_sopka_menu_for_media "${media_path}" || fail
      fi
    done

  fi

  if [ -d "keys" ]; then
    key_storage::add_sopka_menu_for_media "." || fail
  fi
}

key_storage::add_sopka_menu_for_media() {
  local media_path="$1"

  sopka_menu::add_header "Key storage in: ${media_path}" || fail
  
  sopka_menu::add key_storage::maintain_checksums "${media_path}" || fail
  sopka_menu::add key_storage::make_copies "${media_path}" || fail
  
  local password_store_remote_path="keys/password-store/workstation"
  local password_store_path="${HOME}/.password-store"

  if [ -d "${password_store_path}/.git" ]; then
    if [ -d "${media_path}/${password_store_remote_path}" ]; then
      sopka_menu::add key_storage::add_or_update_password_store_remote "${media_path}" "${password_store_remote_path}" || fail
    else
      sopka_menu::add key_storage::create_password_store_remote_repo "${media_path}" "${password_store_remote_path}" || fail
    fi
  fi
  
  if [ ! -d "${password_store_path}" ]; then
    if [ -d "${media_path}/${password_store_remote_path}" ]; then
      sopka_menu::add key_storage::clone_password_store_remote_repo_to_home "${media_path}" "${password_store_remote_path}" || fail
    fi
  fi
}

key_storage::maintain_checksums() {
  local media_path="$1"

  local dir; for dir in "${media_path}/keys/"*; do
    if [ -d "${dir}" ] && [ -f "${dir}/checksums.txt" ]; then
      fs::with_secure_temp_dir_if_available checksums::create_or_update "${dir}" "checksums.txt" || fail
    fi
  done

  local dir; for dir in "${media_path}/copies-of-keys/"* "${media_path}/copies-of-keys/"*/keys/*; do
    if [ -d "${dir}" ] && [ -f "${dir}/checksums.txt" ]; then
      fs::with_secure_temp_dir_if_available checksums::verify "${dir}" "checksums.txt" || fail
    fi
  done
}

key_storage::make_copies() {
  local media_path="$1"

  local copies_dir="${media_path}/copies-of-keys"
  local dest_dir; dest_dir="${copies_dir}/$(date --utc +"%Y%m%dT%H%M%SZ")" || fail

  dir::make_if_not_exists "${copies_dir}" || fail
  dir::make_if_not_exists "${dest_dir}" || fail

  cp -R "${media_path}/keys" "${dest_dir}" || fail

  SOPKA_CREATE_CHECKSUMS_WITHOUT_CONFIRMATION=true fs::with_secure_temp_dir_if_available checksums::create_or_update "${dest_dir}" "checksums.txt" || fail

  sync || fail
  echo "Copies were made: ${dest_dir}"
}

key_storage::add_or_update_password_store_remote() {(
  local media_path="$1"
  local password_store_remote_path="$2"

  local repo_path="${media_path}/${password_store_remote_path}"
  local remote_name; remote_name="$(basename "${media_path}")" || fail

  local password_store_path="${HOME}/.password-store"

  cd "${password_store_path}" || fail

  git::add_or_update_remote "${remote_name}" "${repo_path}" || fail
  git branch --move --force main || fail
  git push --set-upstream "${remote_name}" main || fail
)}

key_storage::create_password_store_remote_repo() {
  local media_path="$1"
  local password_store_remote_path="$2"

  local repo_path="${media_path}/${password_store_remote_path}"

  git init --bare "${repo_path}" || fail

  key_storage::add_or_update_password_store_remote "${media_path}" "${password_store_remote_path}" || fail
}

key_storage::clone_password_store_remote_repo_to_home() {
  local media_path="$1"
  local password_store_remote_path="$2"

  local repo_path="${media_path}/${password_store_remote_path}"
  local remote_name; remote_name="$(basename "${media_path}")" || fail

  local password_store_path="${HOME}/.password-store"

  if [ ! -d "${password_store_path}" ]; then
    git clone --origin "${remote_name}" "${repo_path}" "${password_store_path}" || fail
  fi
}

if declare -f sopka_menu::add >/dev/null; then
  key_storage::populate_sopka_menu || fail
fi
