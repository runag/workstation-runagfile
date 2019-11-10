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

  if [ ! -f "${dst}" ]; then
    sudo cp macos/limit.maxfiles.plist "${dst}" || fail "Unable to copy to $dst ($?)"

    sudo chmod 0644 "${dst}" || fail "Unable to chmod ${dst} ($?)"

    sudo chown root:wheel "${dst}" || fail "Unable to chown ${dst} ($?)"

    echo "increase-maxfiles-limit: reboot required!"
  fi
}

macos::deploy-workstation() {
  # init footnotes
  deploy-lib::footnotes::init || fail

  # maxfiles limit
  macos::increase-maxfiles-limit || fail

  # basic packages
  macos::install-basic-packages || fail

  if [ "${DEPLOY_NON_DEVELOPER_WORKSTATION:-}" != "true" ]; then
    # developer packages
    macos::install-developer-packages || fail

    # shell aliases
    deploy-lib::install-shellrcd || fail
    deploy-lib::install-shellrcd::use-nano-editor || fail
    deploy-lib::install-shellrcd::my-computer-deploy-shell-alias || fail
    data-pi::install-shellrcd::shell-aliases || fail

    # SSH keys
    deploy-lib::install-ssh-keys || fail

    # git
    deploy-lib::configure-git || fail

    # vscode
    vscode::install-config || fail
    vscode::install-extensions || fail

    # sublime text
    sublime::install-config || fail
  fi

  # flush footnotes
  deploy-lib::footnotes::flush || fail

  # communicate to the user that we have reached the end of a script without major errors
  echo "macos::deploy-workstation completed"
}
