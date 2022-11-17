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

# shellcheck disable=2086
workstation::linux::backup::populate_sopka_menu() {
  sopka_menu::add ${1:-} workstation::linux::backup::create || fail
  sopka_menu::add ${1:-} workstation::linux::backup::list_snapshots || fail
  sopka_menu::add ${1:-} workstation::linux::backup::check_and_read_data || fail
  sopka_menu::add ${1:-} workstation::linux::backup::forget || fail
  sopka_menu::add ${1:-} workstation::linux::backup::prune || fail
  sopka_menu::add ${1:-} workstation::linux::backup::maintenance || fail
  sopka_menu::add ${1:-} workstation::linux::backup::unlock || fail
  sopka_menu::add ${1:-} workstation::linux::backup::mount || fail
  sopka_menu::add ${1:-} workstation::linux::backup::umount || fail
  sopka_menu::add ${1:-} workstation::linux::backup::restore || fail
  sopka_menu::add ${1:-} workstation::linux::backup::local_shell || fail
  sopka_menu::add ${1:-} workstation::linux::backup::remote_shell || fail
}

if [[ "${OSTYPE}" =~ ^linux ]] && command -v restic >/dev/null && declare -f sopka_menu::add >/dev/null; then
  sopka_menu::add_header "Linux workstation backup" || fail

  sopka_menu::add workstation::linux::backup::deploy_credentials backup/personal || fail

  workstation::linux::backup::populate_sopka_menu || fail
fi

workstation::linux::backup::env() {
  local config_dir="${HOME}/.workstation-backup"

  dir::make_if_not_exists_and_set_permissions "${config_dir}" 0700 || fail
  dir::make_if_not_exists_and_set_permissions "${config_dir}/restic" 0700 || fail

  export RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-"${config_dir}/restic/password"}"

  if [ -z "${RESTIC_REPOSITORY:-}" ]; then
    export RESTIC_REPOSITORY_FILE="${RESTIC_REPOSITORY_FILE:-"${config_dir}/restic/repository"}"
  fi

  export RESTIC_COMPRESSION="${RESTIC_COMPRESSION:-"auto"}"
}

workstation::linux::backup::deploy_credentials() {(
  workstation::linux::backup::env || fail

  local profile_path="$1"
  local profile_name; profile_name="${2:-"$(basename "${profile_path}")"}" || fail

  # install ssh profile  
  ssh::install_ssh_profile_from_pass "${profile_path}/ssh" "backup-${profile_name}" || fail

  # install restic key
  pass::use "${profile_path}/restic/password" pass::file "${RESTIC_PASSWORD_FILE}" --mode 0600 || fail
  pass::use "${profile_path}/restic/repository" pass::file "${RESTIC_REPOSITORY_FILE}" --mode 0600 || fail
)}

workstation::linux::backup::create() {(
  workstation::linux::backup::env || fail

  cd "${HOME}" || fail

  if ! restic cat config >/dev/null 2>&1; then
    restic init || fail "Unable to init restic repository"
  fi

  local machine_id; machine_id="$(os::machine_id)" || fail

  restic backup \
    --one-file-system \
    --tag "machine-id:${machine_id}" \
    --exclude "${HOME}/Downloads" \
    --exclude "${HOME}/snap" \
    --exclude "${HOME}/.cache" \
    --exclude "${HOME}/.local/share/Trash" \
    . || fail

  # TODO: keep an eye on the snap exclude, are there any documents that might get stored in that directory?
)}

workstation::linux::backup::list_snapshots() {(
  workstation::linux::backup::env || fail

  restic snapshots || fail
)}

workstation::linux::backup::check_and_read_data() {(
  workstation::linux::backup::env || fail

  restic check --check-unused --read-data || fail
)}

workstation::linux::backup::forget() {(
  workstation::linux::backup::env || fail

  restic forget \
    --group-by "host,paths,tags" \
    --keep-within 14d \
    --keep-within-daily 30d \
    --keep-within-weekly 3m \
    --keep-within-monthly 2y || fail
)}

workstation::linux::backup::prune() {(
  workstation::linux::backup::env || fail

  restic prune || fail
)}

workstation::linux::backup::maintenance() {(
  workstation::linux::backup::env || fail

  restic check || fail
  workstation::linux::backup::forget || fail
  workstation::linux::backup::prune || fail
)}

workstation::linux::backup::unlock() {(
  workstation::linux::backup::env || fail

  restic unlock || fail
)}

workstation::linux::backup::mount() {(
  workstation::linux::backup::env || fail

  local mount_point="${HOME}/workstation-backup-mount"

  if findmnt --mountpoint "${mount_point}" >/dev/null; then
    fusermount -u "${mount_point}" || fail
  fi

  dir::make_if_not_exists_and_set_permissions "${mount_point}" 0700 || fail

  restic mount "${mount_point}" || fail
)}

workstation::linux::backup::umount() {(
  workstation::linux::backup::env || fail

  local mount_point="${HOME}/workstation-backup-mount"

  fusermount -u -z "${mount_point}" || fail
)}

workstation::linux::backup::restore() {(
  workstation::linux::backup::env || fail

  local snapshot="${1:-"latest"}"

  local restore_path="${HOME}/workstation-backup-${snapshot}-restore"

  if [ -d "${restore_path}" ]; then
    fail "Restore directory already exists, unable to restore"
  fi

  dir::make_if_not_exists_and_set_permissions "${restore_path}" 0700 || fail

  restic restore --target "${restore_path}" --verify "${snapshot}" || fail
)}

workstation::linux::backup::local_shell() {(
  workstation::linux::backup::env || fail

  "${SHELL}"
)}

workstation::linux::backup::remote_shell() {(
  workstation::linux::backup::env || fail

  local remote_proto remote_host remote_path

  # TODO: RESTIC_REPOSITORY support
  <"${RESTIC_REPOSITORY_FILE}" IFS=: read -r remote_proto remote_host remote_path || fail

  test "${remote_proto}" = sftp || fail

  ssh -t "${remote_host}" "cd $(printf "%q" "${remote_path}"); exec \"\${SHELL}\" -l"
)}
