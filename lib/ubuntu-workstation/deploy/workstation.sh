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
  if [ -n "${DISPLAY:-}" ]; then
    sopka-menu::add ubuntu-workstation::deploy-full-workstation || fail
    sopka-menu::add ubuntu-workstation::deploy-workstation-base || fail
  fi
fi

ubuntu-workstation::deploy-full-workstation() {
  ubuntu-workstation::deploy-workstation-base || fail

  # subshell to deploy secrets
  (
    ubuntu-workstation::deploy-secrets || fail

    if vmware::is-inside-vm; then
      ubuntu-workstation::deploy-host-folders-access || fail
    fi

    ubuntu-workstation::deploy-tailscale || fail
    ubuntu-workstation::backup::deploy || fail
  ) || fail

  log::success "Done ubuntu-workstation::deploy-full-workstation" || fail
}

ubuntu-workstation::deploy-workstation-base() {
  export SOPKA_TASK_STDERR_FILTER=task::install-filter

  # disable screen lock
  gsettings set org.gnome.desktop.session idle-delay 0 || fail

  # perform autoremove, update and upgrade
  apt::autoremove-lazy-update-and-maybe-dist-upgrade || fail

  # install tools to use by the rest of the script
  task::run apt::install-tools || fail

  # shellrc
  task::run ubuntu-workstation::install-shellrc || fail

  # install system software
  task::run ubuntu-workstation::install-system-software || fail

  # configure system
  task::run ubuntu-workstation::configure-system || fail

  # install terminal software
  task::run ubuntu-workstation::install-terminal-software || fail

  # configure git
  task::run workstation::configure-git || fail

  # install build tools
  task::run ubuntu-workstation::install-build-tools || fail

  # install and configure servers
  task::run ubuntu-workstation::install-servers || fail
  task::run ubuntu-workstation::configure-servers || fail

  # programming languages
  task::run ubuntu-workstation::install-and-update-nodejs::nodenv || fail
  task::run-with-rubygems-fail-detector ubuntu-workstation::install-and-update-ruby::rbenv || fail
  task::run ubuntu-workstation::install-and-update-python || fail

  # install & configure desktop software
  task::run ubuntu-workstation::install-desktop-software::apt || fail
  if [ -n "${DISPLAY:-}" ]; then
    task::run ubuntu-workstation::configure-desktop-software || fail
  fi

  # possible interactive part (so without task::run)

  # install vscode configuration
  workstation::vscode::install-config || fail

  # install sublime merge configuration
  workstation::sublime-merge::install-config || fail

  # install sublime text configuration
  workstation::sublime-text::install-config || fail

  # snap stuff
  ubuntu-workstation::install-desktop-software::snap || fail

  log::success "Done ubuntu-workstation::deploy-workstation-base" || fail
}
