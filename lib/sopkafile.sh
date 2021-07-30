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

sopkafile::menu() {
  local list=()

  if [[ "$OSTYPE" =~ ^linux ]]; then
    list+=(sopkafile::change-hostname)

    if [ -n "${DISPLAY:-}" ]; then
      list+=(ubuntu-workstation::deploy-full-workstation)
      list+=(ubuntu-workstation::deploy-workstation-base)
      list+=(ubuntu-workstation::deploy-secrets)
    fi
    if vmware::is-inside-vm; then
      list+=(ubuntu-workstation::deploy-host-folders-access)
    fi
    list+=(ubuntu-workstation::deploy-tailscale)
    list+=(ubuntu-workstation::deploy-backup)
    list+=(ubuntu-workstation::install-shellrc)

    list+=(ubuntu-vm-server::deploy)

    # list+=("backup::vm-home-to-host restic::menu with-systemd")
    # list+=(backup::vm-home-to-host::create)
    # list+=(backup::vm-home-to-host::forget-and-check)

  elif [[ "$OSTYPE" =~ ^darwin ]]; then
    list+=(macos-workstation::deploy)
    list+=(macos-workstation::configure)

  elif [[ "$OSTYPE" =~ ^msys ]]; then
    list+=(windows-workstation::deploy)
  fi

  list+=(workstation::update-home-sopka)
  if [ -f "${HOME}/.sopka.workstation.deployed" ]; then
    list+=(workstation::merge-configs)
  fi

  if [[ "$OSTYPE" =~ ^linux ]] || [[ "$OSTYPE" =~ ^darwin ]]; then
    if command -v sysbench >/dev/null; then
      list+=(benchmark::run)
    fi
  fi

  menu::select-and-run "${list[@]}" || fail
}

sopkafile::change-hostname() {
  local hostname
  echo "Please enter new hostname:"
  IFS="" read -r hostname || fail

  linux::dangerously-set-hostname "${hostname}" || fail

  sopkafile::menu || fail
}
