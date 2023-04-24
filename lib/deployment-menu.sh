#!/usr/bin/env bash

#  Copyright 2012-2022 Rùnag project contributors
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

workstation::deployment::runagfile_menu() {

  # linux workstation
  if runagfile_menu::necessary --os linux; then
    runagfile_menu::add --header "Linux workstation: complete deploy script" || fail

    runagfile_menu::add workstation::linux::deploy_workstation || fail

    runagfile_menu::add --header "Linux workstation: particular deployment tasks" || fail

    runagfile_menu::add workstation::linux::install_packages || fail
    runagfile_menu::add workstation::linux::configure || fail
    runagfile_menu::add workstation::linux::deploy_tailscale tailscale/personal || fail # TODO: list options
    runagfile_menu::add workstation::linux::deploy_lan_server || fail
    
    if vmware::is_inside_vm; then
      runagfile_menu::add workstation::linux::deploy_vm_host_directory_mounts windows-cifs/personal || fail # TODO: list options
    fi
  
    runagfile_menu::add workstation::linux::dangerously_set_hostname || fail

    if linux::display_if_restart_required::is_available; then
      runagfile_menu::add workstation::linux::display_if_restart_required || fail
    fi
  fi


  # macos workstation
  if runagfile_menu::necessary --os darwin; then
    runagfile_menu::add --header "macOS workstation" || fail
    
    runagfile_menu::add workstation::macos::install_packages || fail
    runagfile_menu::add workstation::macos::configure || fail
    runagfile_menu::add workstation::macos::start_developer_servers || fail
  fi


  # windows workstation
  if runagfile_menu::necessary --os msys; then
    runagfile_menu::add --header "Windows workstation" || fail

    runagfile_menu::add workstation::windows::install_packages || fail
    runagfile_menu::add workstation::windows::configure || fail
    runagfile_menu::add workstation::windows::configure_runag_git_directories_as_safe || fail
  fi


  # licenses
  runagfile_menu::add --header "Licenses" || fail

  runagfile_menu::add workstation::sublime_merge::install_license sublime-merge/personal || fail # TODO: list options
  runagfile_menu::add workstation::sublime_text::install_license sublime-text/personal || fail # TODO: list options


  # development
  runagfile_menu::add --header "Development" || fail

  runagfile_menu::add workstation::remove_nodejs_and_ruby_installations || fail
  runagfile_menu::add workstation::merge_editor_configs || fail


  # runagfiles
  runag::runagfile_menu || fail
  runagfile_menu::add workstation::add_runagfiles deployment-repository/personal || fail # TODO: list options
}
