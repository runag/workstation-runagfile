#!/usr/bin/env bash

#  Copyright 2012-2024 Rùnag project contributors
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
    menu::add --header "Linux workstation: complete deploy script" || softfail || return $?

    menu::add workstation::linux::deploy_workstation || softfail || return $?

    menu::add --header "Linux workstation: particular deployment tasks" || softfail || return $?

    if [ "$(systemd-detect-virt)" != "vmware" ]; then
      menu::add --note "VMware tasks are not displayed" || softfail || return $?
    fi

    if ! linux::display_if_restart_required::is_available; then
      menu::add --note "display_if_restart_required is not available" || softfail || return $?
    fi

    if [ -d "${HOME}/.runag/.virt-deploy-keys" ]; then
      menu::add workstation::linux::deploy_virt_keys || softfail || return $?
    fi

    menu::add workstation::linux::deploy_identities || softfail || return $?
    menu::add workstation::linux::install_packages || softfail || return $?
    menu::add workstation::linux::configure || softfail || return $?
    menu::add workstation::linux::set_hostname || softfail || return $?
    
    if [ "$(systemd-detect-virt)" = "vmware" ]; then
      menu::add workstation::linux::deploy_host_cifs_mount identity/my/host-cifs/credentials shared-files host-shared-files || softfail || return $?
    fi

    if linux::display_if_restart_required::is_available; then
      menu::add workstation::linux::display_if_restart_required || softfail || return $?
    fi
  fi


  # macos workstation
  if menu::is_necessary --os darwin; then
    menu::add --header "macOS workstation" || softfail || return $?
    
    menu::add workstation::macos::install_packages || softfail || return $?
    menu::add workstation::macos::configure || softfail || return $?
    menu::add workstation::macos::start_developer_servers || softfail || return $?
  fi


  # windows workstation
  if menu::is_necessary --os msys; then
    menu::add --header "Windows workstation" || softfail || return $?
    menu::add workstation::windows::configure || softfail || return $?
  fi


  # development
  menu::add --header "Development" || softfail || return $?

  menu::add workstation::remove_nodejs_and_ruby_installations || softfail || return $?
  menu::add workstation::merge_editor_configs || softfail || return $?
  menu::add git::add_signed_off_by_trailer_in_commit_msg_hook || softfail || return $?


  # runagfiles
  runag::menu || fail

  # storage
  if menu::is_necessary --os linux; then
    menu::add --header "Storage devices" || softfail || return $?
    menu::add workstation::linux::storage::check_root || softfail || return $?
  fi


  # benchmark
  if menu::is_necessary --os linux; then
    menu::add --header "Benchmark" || softfail || return $?
    if benchmark::is_available; then
      menu::add workstation::linux::run_benchmark || softfail || return $?
    else
      menu::add --note "Benchmark is not available" || softfail || return $?
    fi
  fi


  # password generator
  if menu::is_necessary --os linux; then
    menu::add --header "Password generator" || softfail || return $?
    menu::add workstation::linux::generate_password || softfail || return $?
  fi
}
