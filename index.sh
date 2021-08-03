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

. "${SOPKAFILE_DIR}/lib/sopkafile.sh" || fail
. "${SOPKAFILE_DIR}/lib/workstation.sh" || fail
. "${SOPKAFILE_DIR}/lib/sublime/sublime.sh" || fail
. "${SOPKAFILE_DIR}/lib/vscode/vscode.sh" || fail

if [[ "${OSTYPE}" =~ ^linux ]]; then
  . "${SOPKAFILE_DIR}/lib/linux/backup.sh" || fail
  . "${SOPKAFILE_DIR}/lib/linux/nvidia.sh" || fail
  . "${SOPKAFILE_DIR}/lib/linux/ubuntu-vm-server.sh" || fail
  . "${SOPKAFILE_DIR}/lib/linux/ubuntu-workstation.sh" || fail
  . "${SOPKAFILE_DIR}/lib/linux/ubuntu-workstation/configure.sh" || fail
  . "${SOPKAFILE_DIR}/lib/linux/ubuntu-workstation/install.sh" || fail

elif [[ "${OSTYPE}" =~ ^darwin ]]; then
  . "${SOPKAFILE_DIR}/lib/macos/macos-workstation.sh" || fail

elif [[ "${OSTYPE}" =~ ^msys ]]; then
  . "${SOPKAFILE_DIR}/lib/windows/windows-workstation.sh" || fail
fi

sopkafile::main() {
  sopkafile::menu || fail
}
