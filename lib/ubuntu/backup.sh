#!/usr/bin/env bash

#  Copyright 2012-2020 Stanislav Senotrusov <stan@senotrusov.com>
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

backup::vm-home-to-host() {
  backup::vm-home-to-host::load-configuration || fail
  "$@" || fail
}

backup::vm-home-to-host::load-configuration() {
  local machineUuid; machineUuid="$(vmware::get-machine-uuid)" || fail

  export BACKUP_NAME="vm-home-to-host"
  export RESTIC_REPOSITORY="${HOME}/my/storage/vm-home-backups/${machineUuid}"
  export RESTIC_PASSWORD="null"
}

backup::vm-home-to-host::setup() (
  file::sudo-write "/etc/sudoers.d/dmidecode" 0440 root <<SHELL || fail
${USER} ALL=NOPASSWD: /usr/sbin/dmidecode
SHELL

  backup::vm-home-to-host::load-configuration || fail

  # install systemd service
  declare -A serviceOptions
  serviceOptions[NoNewPrivileges]=false
  restic::systemd::init-service serviceOptions || fail

  # enable timer
  declare -A timerOptions
  timerOptions[OnCalendar]="*:00/30"
  timerOptions[RandomizedDelaySec]="300"
  restic::systemd::enable-timer timerOptions || fail
)

backup::vm-home-to-host::create() (
  backup::vm-home-to-host::load-configuration || fail

  # I should probably make a special user service to wait until the network is up and the directory is mounted
  findmnt -M "${HOME}/my" >/dev/null || fail

  if [ ! -d "${RESTIC_REPOSITORY}" ]; then
    restic::init || fail
  fi

  # The purpose of this is to have relative paths in backup
  cd "${HOME}" || fail

  local quietMaybe=""; test -t 1 || quietMaybe="--quiet"

  restic backup $quietMaybe --one-file-system . || fail

  tools::do-once-per-day backup::vm-home-to-host::forget-and-check || fail
)

backup::vm-home-to-host::forget-and-check() {
  backup::vm-home-to-host::load-configuration || fail

  restic::forget-and-prune || fail
  restic::check-and-read-data || fail
}
