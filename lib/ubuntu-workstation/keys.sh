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

ubuntu_workstation::keys::populate_sopka_menu() {
  if [[ "${OSTYPE}" =~ ^linux ]]; then
    local dir; for dir in "/media/${USER}"/KEYS-* ; do
      if [ -d "$dir" ]; then
        sopka_menu::add_header Keys || fail
        sopka_menu::add ubuntu_workstation::keys::maintain_checksums "${dir}" || fail
        sopka_menu::add ubuntu_workstation::keys::make_backups "${dir}" || fail
        sopka_menu::add_delimiter || fail
      fi
    done
  fi
}

if declare -f sopka_menu::add >/dev/null; then
  ubuntu_workstation::keys::populate_sopka_menu || fail
fi

ubuntu_workstation::keys::maintain_checksums() {
  local media="$1"

  local dir; for dir in "${media}"/*keys* ; do
    if [ -d "${dir}" ]; then
      linux::with_secure_temp_dir checksums::create_or_update "${dir}" "checksums.txt" || fail
    fi
  done

  local dir; for dir in "${media}"/copies/*/* ; do
    if [ -d "${dir}" ]; then
      linux::with_secure_temp_dir checksums::verify "${dir}" "checksums.txt" || fail
    fi
  done
}

ubuntu_workstation::keys::make_backups() {
  local media="$1"
  
  local dest_dir; dest_dir="${media}/copies/$(date --utc +"%Y%m%dT%H%M%SZ")" || fail

  dir::make_if_not_exists "${media}/copies" || fail
  dir::make_if_not_exists "${dest_dir}" || fail

  local dir; for dir in "${media}"/*keys* ; do
    if [ -d "${dir}" ]; then
      cp -R "${dir}" "${dest_dir}" || fail
    fi
  done
  sync || fail
  echo "${dest_dir}"
}
