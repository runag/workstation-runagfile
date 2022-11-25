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

workstation::backup::create() {
  cd "${HOME}" || softfail || return $?

  if ! restic cat config >/dev/null 2>&1; then
    # set compression=none for parent folder if repository will be on local btrfs
    if [[ ! "${RESTIC_REPOSITORY}" =~ .+:.+ ]]; then
      local parent_dir; parent_dir="$(dirname "${RESTIC_REPOSITORY}")" || softfail || return $?

      ( umask 0077 && mkdir -p "${parent_dir}" ) || softfail || return $?

      if command -v btrfs >/dev/null && btrfs property get "${parent_dir}" compression >/dev/null; then
        btrfs property set "${parent_dir}" compression none || softfail || return $?
      fi
    fi

    restic init || softfail "Unable to init restic repository" || return $?
  fi

  local machine_id; machine_id="$(os::machine_id)" || softfail || return $?

  # TODO: keep an eye on the snap exclude, are there any documents that might get stored in that directory?

  restic backup \
    --one-file-system \
    --tag "machine-id:${machine_id}" \
    --exclude "${HOME}/.cache" \
    --exclude "${HOME}/.local/share/Trash" \
    --exclude "${HOME}/Downloads" \
    --exclude "${HOME}/snap" \
    --exclude "${HOME}/workstation-backup" \
    . || softfail || return $?
}

workstation::backup::snapshots() {
  restic snapshots || softfail || return $?
}

workstation::backup::check() {
  restic check --check-unused --read-data || softfail || return $?
}

workstation::backup::forget() {
  restic forget \
    --group-by "host,paths,tags" \
    --keep-within 14d \
    --keep-within-daily 30d \
    --keep-within-weekly 3m \
    --keep-within-monthly 2y || softfail || return $?
}

workstation::backup::prune() {
  restic prune || softfail || return $?
}

workstation::backup::maintenance() {
  restic check || softfail || return $?
  workstation::backup::forget || softfail || return $?
  workstation::backup::prune || softfail || return $?
}

workstation::backup::unlock() {
  restic unlock || softfail || return $?
}


# restore

workstation::backup::mount() {
  local output_folder; output_folder="$(workstation::backup::get_output_folder)" || softfail || return $?

  output_folder+="/mount"
  dir::make_if_not_exists_and_set_permissions "${output_folder}" 0700 || softfail || return $?

  if findmnt --mountpoint "${output_folder}" >/dev/null; then
    fusermount -u "${output_folder}" || softfail || return $?
  fi

  restic mount "${output_folder}" || softfail || return $?
}

workstation::backup::umount() {
  local output_folder; output_folder="$(workstation::backup::get_output_folder)" || softfail || return $?

  output_folder+="/mount"

  fusermount -u -z "${output_folder}" || softfail || return $?
}

workstation::backup::restore() {
  local snapshot_id="${1:-"latest"}"

  local output_folder; output_folder="$(workstation::backup::get_output_folder)" || softfail || return $?

  output_folder+="/restore"
  dir::make_if_not_exists_and_set_permissions "${output_folder}" 0700 || softfail || return $?

  output_folder+="/${snapshot_id}"

  if [ -d "${output_folder}" ]; then
    fail "Restore directory already exists, unable to restore"
  fi

  dir::make_if_not_exists_and_set_permissions "${output_folder}" 0700 || softfail || return $?

  restic restore --target "${output_folder}" --verify "${snapshot_id}" || softfail || return $?
}


# shell

workstation::backup::shell() {
  "${SHELL}"
  softfail_unless_good "shell failed ($?)" $? || return $?
}

# shellcheck disable=2031
workstation::backup::remote_shell() {
  local remote_proto remote_host remote_path

  <<<"${RESTIC_REPOSITORY}" IFS=: read -r remote_proto remote_host remote_path || softfail || return $?

  test "${remote_proto}" = sftp || softfail || return $?

  ssh -t "${remote_host}" "cd $(printf "%q" "${remote_path}"); exec \"\${SHELL}\" -l"
  softfail_unless_good "remote shell failed ($?)" $? || return $?
}
