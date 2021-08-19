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

sopkafile::load() {
  local selfDir; selfDir="$(dirname "${BASH_SOURCE[0]}")" || fail

  . "${selfDir}/config.sh" || fail

  . "${selfDir}/lib/workstation.sh" || fail

  if [[ "${OSTYPE}" =~ ^darwin ]]; then . "${selfDir}/lib/macos-workstation.sh" || fail; fi
  if [[ "${OSTYPE}" =~ ^linux ]]; then . "${selfDir}/lib/ubuntu-workstation.sh" || fail; fi
  if [[ "${OSTYPE}" =~ ^msys ]]; then . "${selfDir}/lib/windows-workstation.sh" || fail; fi

  . "${selfDir}/lib/sublime/sublime.sh" || fail
  . "${selfDir}/lib/vscode/vscode.sh" || fail
}

sopkafile::load || fail

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
    sopka::add-menu-item ubuntu-workstation::deploy-tailscale || fail
    sopka::add-menu-item ubuntu-workstation::deploy-vm-server || fail
    sopka::add-menu-item ubuntu-workstation::install-shellrc || fail
    sopka::add-menu-item ubuntu-workstation::change-hostname || fail

    sopka::add-menu-item ubuntu-workstation::backup::deploy || fail
    sopka::add-menu-item ubuntu-workstation::backup::create || fail
    sopka::add-menu-item ubuntu-workstation::backup::list-snapshots || fail
    sopka::add-menu-item ubuntu-workstation::backup::check-and-read-data || fail
    sopka::add-menu-item ubuntu-workstation::backup::forget-and-prune || fail
    sopka::add-menu-item ubuntu-workstation::backup::maintenance || fail
    sopka::add-menu-item ubuntu-workstation::backup::unlock || fail
    sopka::add-menu-item ubuntu-workstation::backup::mount || fail
    sopka::add-menu-item ubuntu-workstation::backup::umount || fail
    sopka::add-menu-item ubuntu-workstation::backup::start || fail
    sopka::add-menu-item ubuntu-workstation::backup::stop || fail
    sopka::add-menu-item ubuntu-workstation::backup::disable-timers || fail
    sopka::add-menu-item ubuntu-workstation::backup::status || fail
    sopka::add-menu-item ubuntu-workstation::backup::log || fail

  elif [[ "${OSTYPE}" =~ ^darwin ]]; then
    sopka::add-menu-item macos-workstation::deploy || fail
    sopka::add-menu-item macos-workstation::configure || fail

  elif [[ "${OSTYPE}" =~ ^msys ]]; then
    sopka::add-menu-item windows-workstation::deploy || fail
  fi

  sopka::add-menu-item workstation::merge-editor-configs || fail

  sopka::add-menu-item "sopka::with-update-secrets sopka::display-menu" || fail
  sopka::add-menu-item sopka::update || fail

  if [[ "${OSTYPE}" =~ ^linux ]]; then
    sopka::add-menu-item keys::maintain-checksums || fail
    sopka::add-menu-item keys::make-backups || fail

    sopka::add-menu-item linux::display-if-restart-required || fail
  fi

  if benchmark::is-available; then
    sopka::add-menu-item benchmark::run || fail
  fi

fi
