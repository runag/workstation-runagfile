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
  windows::configure-workstation || fail
}

windows::configure-workstation() {
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

  # SSH keys
  ssh::install-keys || fail
}
