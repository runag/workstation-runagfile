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

if [[ "${OSTYPE}" =~ ^linux ]] && declare -f sopka-menu::add >/dev/null; then
  sopka-menu::add ubuntu-workstation::deploy-shellrc || fail
  sopka-menu::add ubuntu-workstation::change-hostname || fail
fi

ubuntu-workstation::deploy-shellrc() {
  ubuntu-workstation::install-shellrc || fail

  log::success "Done ubuntu-workstation::deploy-shellrc" || fail
}

ubuntu-workstation::change-hostname() {
  local hostname
  echo "Please enter new hostname:"
  IFS="" read -r hostname || fail

  linux::dangerously-set-hostname "${hostname}" || fail

  log::success "Done ubuntu-workstation::change-hostname" || fail
}
