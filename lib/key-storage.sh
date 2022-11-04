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
    local media_path; for media_path in "/Volumes"/*KEYS* ; do
      if [ -d "${media_path}" ]; then
        key_storage::add_sopka_menu_for_media "${media_path}" || fail
      fi
    done

  elif [[ "${OSTYPE}" =~ ^linux ]]; then
    local media_path; for media_path in "/media/${USER}"/*KEYS* ; do
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

  # Checksums
  sopka_menu::add key_storage::maintain_checksums "${media_path}" || fail
  sopka_menu::add key_storage::make_copies "${media_path}" || fail

  # Scopes
  local scope_path; for scope_path in "${media_path}"/keys/* ; do
    if [ -d "${scope_path}" ] && [ ! -f "${scope_path}/exclude-from-sopka-menu" ]; then

      local media_name; media_name="$(basename "${media_path}")" || fail
      local scope_name; scope_name="$(basename "${scope_path}")" || fail
      local git_remote_name="${media_name}/${scope_name}" || fail

      key_storage::add_sopka_menu_for_password_store "${scope_path}" "${git_remote_name}" || fail
    fi
  done
}

key_storage::add_sopka_menu_for_password_store() {
  local scope_path="$1"
  local git_remote_name="$2"

  local password_store_dir_path="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  local password_store_git_remote_path="${scope_path}/password-store"

  if [ -d "${password_store_dir_path}/.git" ]; then
    if [ -d "${password_store_git_remote_path}" ]; then
      sopka_menu::add key_storage::add_or_update_password_store_git_remote "${git_remote_name}" "${password_store_git_remote_path}" || fail
    else
      sopka_menu::add key_storage::create_password_store_git_remote "${git_remote_name}" "${password_store_git_remote_path}" || fail
    fi
  fi

  if [ ! -d "${password_store_dir_path}" ]; then
    if [ -d "${password_store_git_remote_path}" ]; then
      sopka_menu::add key_storage::clone_password_store_git_remote_to_local "${git_remote_name}" "${password_store_git_remote_path}" || fail
    fi
  fi
}

### Checksums

key_storage::maintain_checksums() {
  local media_path="$1"

  local dir; for dir in "${media_path}/keys"/*/*; do
    if [ -d "${dir}" ] && [ -f "${dir}/checksums.txt" ]; then
      fs::with_secure_temp_dir_if_available checksums::create_or_update "${dir}" "checksums.txt" || fail
    fi
  done

  local dir; for dir in "${media_path}/copies-of-keys"/* "${media_path}/copies-of-keys"/*/keys/*/*; do
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

### Password store

key_storage::add_or_update_password_store_git_remote() {(
  local git_remote_name="$1"
  local password_store_git_remote_path="$2"

  local password_store_dir_path="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  cd "${password_store_dir_path}" || fail

  git::add_or_update_remote "${git_remote_name}" "${password_store_git_remote_path}" || fail
  git branch --move --force main || fail
  git push --set-upstream "${git_remote_name}" main || fail
)}

key_storage::create_password_store_git_remote() {
  local git_remote_name="$1"
  local password_store_git_remote_path="$2"

  local password_store_dir_path="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  git init --bare "${password_store_git_remote_path}" || fail

  key_storage::add_or_update_password_store_git_remote "${git_remote_name}" "${password_store_git_remote_path}" || fail
}

key_storage::clone_password_store_git_remote_to_local() {
  local git_remote_name="$1"
  local password_store_git_remote_path="$2"

  local password_store_dir_path="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  if [ ! -d "${password_store_dir_path}" ]; then
    git clone --origin "${git_remote_name}" "${password_store_git_remote_path}" "${password_store_dir_path}" || fail
  fi
}

if declare -f sopka_menu::add >/dev/null; then
  key_storage::populate_sopka_menu || fail
fi
