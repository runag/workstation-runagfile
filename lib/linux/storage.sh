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

workstation::linux::storage::check_root() {
  if [ "$(findmnt --mountpoint / --noheadings --output FSTYPE --raw 2>/dev/null)" != "btrfs" ]; then
    fail "Check on non-btrfs partition is not implemented"
  fi

  local root_device; root_device="$(findmnt --mountpoint / --noheadings --output SOURCE --raw | sed 's/\[\/\@\]$//'; test "${PIPESTATUS[*]}" = "0 0")" || fail

  # "btrfs check --check-data-csum" is not accurate on live filesystem
  sudo btrfs scrub start -B -d "${root_device}" || fail
  sudo btrfs check --readonly --force "${root_device}" || fail
}

workstation::linux::storage::configure_udisks_mount_options() {
  file::write --sudo --mode 0644 /etc/udisks2/mount_options.conf <<SHELL || fail
[defaults]
btrfs_defaults=flushoncommit,noatime,compress=zstd
btrfs_allow=compress,compress-force,datacow,nodatacow,datasum,nodatasum,autodefrag,noautodefrag,degraded,device,discard,nodiscard,subvol,subvolid,space_cache,commit,flushoncommit,noatime
SHELL
}
