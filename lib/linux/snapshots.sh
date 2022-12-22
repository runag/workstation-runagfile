#!/usr/bin/env bash

#  Copyright 2012-2022 Rùnag project contributors
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


# export SNAPSHOTS_TOP_LEVEL_SUBVOLUME_PATH="/mnt/top-level-subvolume"

workstation::linux::snapshots::are_available() {
  [ "$(findmnt --mountpoint /     --noheadings --output FSTYPE,FSROOT --raw 2>/dev/null)" = "btrfs /@" ] &&
  [ "$(findmnt --mountpoint /home --noheadings --output FSTYPE,FSROOT --raw 2>/dev/null)" = "btrfs /@home" ]
}

workstation::linux::snapshots::deploy() {
  workstation::linux::snapshots::add_top_level_subvolume_mount || fail
}

workstation::linux::snapshots::add_top_level_subvolume_mount() {
  local mount_source; mount_source="$(findmnt --mountpoint / --noheadings --output SOURCE --raw | sed 's/\[\/\@\]$//'; test "${PIPESTATUS[*]}" = "0 0")" || fail

  dir::sudo_make_if_not_exists "${SNAPSHOTS_TOP_LEVEL_SUBVOLUME_PATH}" || fail

  <<<"${mount_source}  ${SNAPSHOTS_TOP_LEVEL_SUBVOLUME_PATH}  btrfs  defaults,discard=async,noatime,flushoncommit,commit=15,subvol=/  0  2" file::read_with_updated_block /etc/fstab BTRFS_TOP_LEVEL_SUBVOLUME | fstab::verify_and_write
  test "${PIPESTATUS[*]}" = "0 0" || fail

  sudo mount -a # other mounts might fail, so we ignore exit status here

  findmnt --mountpoint "${SNAPSHOTS_TOP_LEVEL_SUBVOLUME_PATH}" >/dev/null || fail "Filesystem is not mounted"
}

# maybe it's better to not mount top_level_subvolume but create @snapshots subvol and just mount it?
# can I make snapshots of already mounted "/" and "/home"?

# snapshot function
# cleanup function
# system-wide script
# sudo systemd timer & service
