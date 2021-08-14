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

. "${SOPKAFILE_DIR}/lib/workstation.sh" || fail

if [[ "${OSTYPE}" =~ ^darwin ]]; then . "${SOPKAFILE_DIR}/lib/macos-workstation.sh" || fail; fi
if [[ "${OSTYPE}" =~ ^linux ]]; then . "${SOPKAFILE_DIR}/lib/ubuntu-workstation.sh" || fail; fi
if [[ "${OSTYPE}" =~ ^msys ]]; then . "${SOPKAFILE_DIR}/lib/windows-workstation.sh" || fail; fi

. "${SOPKAFILE_DIR}/lib/sublime/sublime.sh" || fail
. "${SOPKAFILE_DIR}/lib/vscode/vscode.sh" || fail

if declare -f sopka::add-menu-item >/dev/null; then
  if [[ "${OSTYPE}" =~ ^linux ]]; then
    if [ -n "${DISPLAY:-}" ]; then
      sopka::add-menu-item ubuntu-workstation::deploy-full-workstation || fail
      sopka::add-menu-item ubuntu-workstation::deploy-workstation-base || fail
      sopka::add-menu-item ubuntu-workstation::deploy-secrets || fail
    fi
    if vmware::is-inside-vm; then
      sopka::add-menu-item ubuntu-workstation::deploy-host-folders-access || fail
    fi
    sopka::add-menu-item ubuntu-workstation::deploy-backup || fail
    sopka::add-menu-item ubuntu-workstation::deploy-tailscale || fail
    sopka::add-menu-item ubuntu-workstation::deploy-vm-server || fail
    sopka::add-menu-item ubuntu-workstation::install-shellrc || fail
    sopka::add-menu-item ubuntu-workstation::change-hostname || fail

    # sopka::add-menu-item "backup::vm-home-to-host restic::menu with-systemd" || fail
    # sopka::add-menu-item backup::vm-home-to-host::create || fail
    # sopka::add-menu-item backup::vm-home-to-host::forget-and-check || fail

  elif [[ "${OSTYPE}" =~ ^darwin ]]; then
    sopka::add-menu-item macos-workstation::deploy || fail
    sopka::add-menu-item macos-workstation::configure || fail

  elif [[ "${OSTYPE}" =~ ^msys ]]; then
    sopka::add-menu-item windows-workstation::deploy || fail
  fi

  sopka::add-menu-item workstation::merge-editor-configs || fail

  sopka::add-menu-item "sopka::with-update-secrets sopka::display-menu" || fail
  sopka::add-menu-item sopka::update-sopka-and-sopkafile || fail

  if [[ "${OSTYPE}" =~ ^linux ]]; then
    sopka::add-menu-item keys::create-update-or-verify-key-checksums-on-all-mounted-media || fail
    sopka::add-menu-item keys::make-backup-copies-on-all-mounted-media || fail
    sopka::add-menu-item linux::display-if-restart-required || fail
  fi

  if [[ "${OSTYPE}" =~ ^linux ]] || [[ "${OSTYPE}" =~ ^darwin ]]; then
    if command -v sysbench >/dev/null; then
      sopka::add-menu-item benchmark::run || fail
    fi
  fi

fi
