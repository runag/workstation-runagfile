#!/usr/bin/env bash

#  Copyright 2012-2019 Stanislav Senotrusov <stan@senotrusov.com>
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

backup::polina-archive() {
  # --checksum
  rclone sync "/Volumes/polina-backup/polina-archive" "onedrive:backups/polina-archive" --progress --bwlimit 500k || fail "rclone sync failed ($?)"
  rclone check "/Volumes/polina-backup/polina-archive" "onedrive:backups/polina-archive" --progress --bwlimit 500k || fail "rclone check failed ($?)"

  deploy-lib::display-elapsed-time || fail
}

backup::stan-archive() {
  # --checksum
  rclone sync "/Volumes/Stan time machine/stan-archive" "onedrive:backups/stan-archive" --progress --bwlimit 500k || fail "rclone sync failed ($?)"
  rclone check "/Volumes/Stan time machine/stan-archive" "onedrive:backups/stan-archive" --progress --bwlimit 500k || fail "rclone check failed ($?)"

  deploy-lib::display-elapsed-time || fail
}
