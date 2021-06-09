#!/usr/bin/env bash

#  Copyright 2012-2021 Stanislav Senotrusov <stan@senotrusov.com>
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

. "${SOPKAFILE_DIR}/config.sh" || fail

. "${SOPKAFILE_DIR}/lib/menu.sh" || fail
. "${SOPKAFILE_DIR}/lib/misc.sh" || fail

. "${SOPKAFILE_DIR}/lib/macos/macos-workstation.sh" || fail
. "${SOPKAFILE_DIR}/lib/sublime/sublime.sh" || fail

. "${SOPKAFILE_DIR}/lib/ubuntu/backup.sh" || fail
. "${SOPKAFILE_DIR}/lib/ubuntu/desktop.sh" || fail
. "${SOPKAFILE_DIR}/lib/ubuntu/ubuntu.sh" || fail

. "${SOPKAFILE_DIR}/lib/vscode/vscode.sh" || fail
. "${SOPKAFILE_DIR}/lib/windows/windows-workstation.sh" || fail

sopkafile::main() {
  sopkafile::menu || fail
}
