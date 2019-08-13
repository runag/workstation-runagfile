#!/usr/bin/env bash

#  Copyright 2012-2016 Stanislav Senotrusov <stan@senotrusov.com>
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

macos::increase-maxfiles-limit() {
  # based on https://unix.stackexchange.com/questions/108174/how-to-persistently-control-maximum-system-resource-consumption-on-mac

  local dst="/Library/LaunchDaemons/limit.maxfiles.plist"

  sudo cp macos/limit.maxfiles.plist "${dst}" || { echo "Unable to copy to $dst (${?})" >&2; exit 1; }

  sudo chmod 0644 "${dst}" || { echo "Unable to chmod ${dst} (${?})" >&2; exit 1; }

  sudo chown root:wheel "${dst}" || { echo "Unable to chown ${dst} (${?})" >&2; exit 1; }

  echo "increase-maxfiles-limit: reboot required!"
}
