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

workstation::linux::set_battery_profile() {
  local profile_function="$1"

  temp_file="$(mktemp)" || fail
  {
    runag::mini_library || fail

    declare -f linux::set_battery_charge_control_threshold || fail
    declare -f "${profile_function}" || fail

    echo 'set -o nounset'
    printf '%q || fail' "${profile_function}" || fail

  } >"${temp_file}" || fail

  file::write --absorb "${temp_file}" --sudo --mode 755 /usr/local/bin/update-workstation-battery-profile || fail

  file::write --sudo /etc/systemd/system/update-workstation-battery-profile.service <<EOF || fail
[Unit]
Description=Update battery profile

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update-workstation-battery-profile

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl --quiet --now enable "update-workstation-battery-profile.service" || fail
}
