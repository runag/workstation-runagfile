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

sopkafile::menu() {
  local list=()

  if [[ "$OSTYPE" =~ ^linux ]]; then
    if [ -f "${HOME}/.sopka.workstation.deployed" ] || sopka::nothing-deployed; then
      list+=(ubuntu::deploy-workstation)
    fi
    if [ -f "${HOME}/.sopka.my-storage-vm.deployed" ] || sopka::nothing-deployed; then
      list+=(my-storage-vm::deploy)
    fi
  fi

  if [[ "$OSTYPE" =~ ^darwin ]]; then
    list+=(macos::deploy-workstation)
    list+=(macos::configure-workstation)
  fi

  if [[ "$OSTYPE" =~ ^msys ]]; then
    list+=(windows::deploy-workstation)
  fi

  if [ -f "${HOME}/.stan-documents.backup-credentials" ]; then
    list+=("backup::stan-documents borg::menu")
    list+=("backup::stan-documents::create")
  fi

  if [ -f "${HOME}/.sopka.workstation.deployed" ]; then
    list+=(deploy::merge-workstation-configs)
  fi

  if [[ "$OSTYPE" =~ ^linux ]] || [[ "$OSTYPE" =~ ^darwin ]]; then
    if command -v sysbench >/dev/null; then
      list+=(benchmark::run)
    fi
  fi

  menu::select-and-run "${list[@]}" || fail
}
