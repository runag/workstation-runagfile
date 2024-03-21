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

workstation::deployment::menu() {

  # linux workstation
  if menu::is_necessary --os linux; then
    menu::add --header "Linux workstation: complete deploy script" || fail

    menu::add workstation::linux::deploy_workstation || fail

    menu::add --header "Linux workstation: particular deployment tasks" || fail

    menu::add workstation::linux::deploy_identities || fail
    menu::add workstation::linux::install_packages || fail
    menu::add workstation::linux::configure || fail
    menu::add workstation::linux::deploy_lan_server || fail
    
    if vmware::is_inside_vm; then
      menu::add workstation::linux::deploy_host_cifs_mount identity/my/host-cifs/credentials shared-files host-shared-files || fail
    else
      menu::add --note "not inside virtual machine" || fail
    fi
  
    menu::add workstation::linux::set_hostname || fail

    if linux::display_if_restart_required::is_available; then
      menu::add workstation::linux::display_if_restart_required || fail
    else
      menu::add --note "display_if_restart_required is not available" || fail
    fi
  fi


  # macos workstation
  if menu::is_necessary --os darwin; then
    menu::add --header "macOS workstation" || fail
    
    menu::add workstation::macos::install_packages || fail
    menu::add workstation::macos::configure || fail
    menu::add workstation::macos::start_developer_servers || fail
  fi


  # windows workstation
  if menu::is_necessary --os msys; then
    menu::add --header "Windows workstation" || fail

    menu::add workstation::windows::install_packages || fail
    menu::add workstation::windows::configure || fail
    menu::add workstation::windows::configure_runag_git_directories_as_safe || fail
  fi


  # development
  menu::add --header "Development" || fail

  menu::add workstation::remove_nodejs_and_ruby_installations || fail
  menu::add workstation::merge_editor_configs || fail


  # storage
  if menu::is_necessary --os linux; then
    menu::add --header "Storage devices" || fail
    menu::add workstation::linux::storage::check_root || fail
  fi


  # benchmark
  if menu::is_necessary --os linux; then
    menu::add --header "Benchmark" || fail
    if benchmark::is_available; then
      menu::add workstation::linux::run_benchmark || fail
    else
      menu::add --note "Benchmark is not available" || fail
    fi
  fi


  # password generator
  if menu::is_necessary --os linux; then
    menu::add --header "Password generator" || fail
    menu::add workstation::linux::generate_password || fail
  fi
}
