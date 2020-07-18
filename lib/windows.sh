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

windows::deploy-workstation() {
  # shell aliases
  shellrcd::install || fail
  shellrcd::use-nano-editor || fail
  shellrcd::sopka-src-path || fail

  # git
  git::configure || fail

  # sublime text
  sublime::install-config || fail

  # vscode
  vscode::install-config || fail
  vscode::install-extensions || fail

  # ssh
  ssh::install-keys || fail
  windows::enable-ssh-agent || fail
}

windows::install-packages() {
  if ! command -v choco >/dev/null; then
    windows::install-chocolatey || fail
  fi

  windows::run-admin-powershell-script "${SOPKA_WIN_DIR}\lib\windows\install-chocolatey-packages.ps1" || fail

  if windows::is-bare-metal; then
    windows::run-admin-powershell-script "${SOPKA_WIN_DIR}\lib\windows\install-chocolatey-packages-desktop.ps1" || fail
  fi

  windows::chocolatey::upgrade-all || fail
}
