#!/usr/bin/env bash

#  Copyright 2012-2022 Stanislav Senotrusov <stan@senotrusov.com>
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

ubuntu_workstation::deploy_full_workstation() {
  ubuntu_workstation::deploy_workstation_base || fail

  # subshell to deploy secrets
  (
    ubuntu_workstation::deploy_secrets || fail

    if vmware::is_inside_vm; then
      ubuntu_workstation::deploy_host_folders_access || fail
    fi

    ubuntu_workstation::deploy_tailscale || fail
    ubuntu_workstation::backup::deploy || fail
  ) || fail

  log::success "Done ubuntu_workstation::deploy_full_workstation" || fail
}

ubuntu_workstation::deploy_workstation_base() {
  export SOPKA_TASK_STDERR_FILTER=task::install_filter

  # disable screen lock
  gsettings set org.gnome.desktop.session idle-delay 0 || fail

  # perform autoremove, update and upgrade
  task::run apt::autoremove_lazy_update_and_maybe_dist_upgrade || fail

  # install tools to use by the rest of the script
  task::run apt::install_sopka_essential_dependencies || fail

  # install display-if-restart-required dependencies
  task::run apt::install_display_if_restart_required_dependencies || fail

  # install benchmark
  task::run benchmark::install::apt || fail

  # shellrc
  task::run ubuntu_workstation::install_shellrc || fail

  # install system software
  task::run ubuntu_workstation::install_system_software || fail

  # configure system
  task::run ubuntu_workstation::configure_system || fail

  # install terminal software
  task::run ubuntu_workstation::install_terminal_software || fail

  # configure git
  task::run workstation::configure_git || fail

  # install build tools
  task::run ubuntu_workstation::install_build_tools || fail

  # install and configure servers
  task::run ubuntu_workstation::install_servers || fail
  task::run ubuntu_workstation::configure_servers || fail

  # programming languages
  task::run ubuntu_workstation::install_and_update_nodejs || fail
  task::run_with_rubygems_fail_detector ubuntu_workstation::install_and_update_ruby || fail
  task::run ubuntu_workstation::install_and_update_python || fail

  # install & configure desktop software
  task::run ubuntu_workstation::install_desktop_software::apt || fail
  if [ -n "${DISPLAY:-}" ]; then
    task::run ubuntu_workstation::configure_desktop_software || fail
  fi


  # possible interactive part (so without task::run)

  # install vscode configuration
  workstation::vscode::install_config || fail

  # install sublime merge configuration
  workstation::sublime_merge::install_config || fail

  # install sublime text configuration
  workstation::sublime_text::install_config || fail


  # snap stuff
  # without task:run here, snap can't understand that he has no terminal to output to and just dumps escape codes to log at large
  ubuntu_workstation::install_desktop_software::snap || fail

  log::success "Done ubuntu_workstation::deploy_workstation_base" || fail
}
