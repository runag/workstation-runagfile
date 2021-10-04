#!/usr/bin/env bash

#  Copyright 2012-2021 Stanislav Senotrusov <stan@senotrusov.com>
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

ubuntu-workstation::keys::populate-sopka-menu() {
  if [[ "${OSTYPE}" =~ ^linux ]]; then
    local dir; for dir in "/media/${USER}"/KEYS-* ; do
      if [ -d "$dir" ]; then
        sopka-menu::add "ubuntu-workstation::keys::maintain-checksums $(printf "%q" "${dir}")" || fail
        sopka-menu::add "ubuntu-workstation::keys::make-backups $(printf "%q" "${dir}")" || fail
      fi
    done
  fi
}

if declare -f sopka-menu::add >/dev/null; then
  ubuntu-workstation::keys::populate-sopka-menu || fail
fi

ubuntu-workstation::keys::maintain-checksums() {
  local media="$1"

  local dir; for dir in "${media}"/*keys* ; do
    if [ -d "${dir}" ]; then
      linux::with-secure-tmpdir checksums::create-or-update "${dir}" "checksums.txt" || fail
    fi
  done

  local dir; for dir in "${media}"/copies/*/* ; do
    if [ -d "${dir}" ]; then
      linux::with-secure-tmpdir checksums::verify "${dir}" "checksums.txt" || fail
    fi
  done
}

ubuntu-workstation::keys::make-backups() {
  local media="$1"
  
  local destDir; destDir="${media}/copies/$(date --utc +"%Y%m%dT%H%M%SZ")" || fail

  dir::make-if-not-exists "${media}/copies" || fail
  dir::make-if-not-exists "${destDir}" || fail

  local dir; for dir in "${media}"/*keys* ; do
    if [ -d "${dir}" ]; then
      cp -R "${dir}" "${destDir}" || fail
    fi
  done
  sync || fail
  echo "${destDir}"
}
