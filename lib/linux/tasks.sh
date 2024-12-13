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

workstation::linux::tasks() {
  # Deploy
  task::add --header "Linux workstation: complete deploy script" || softfail || return $?

  task::add workstation::linux::deploy_workstation || softfail || return $?

  task::add --header "Linux workstation: particular deployment tasks" || softfail || return $?

  task::add workstation::linux::deploy_identities || softfail || return $?
  task::add workstation::linux::install_packages || softfail || return $?
  task::add workstation::linux::configure || softfail || return $?
  task::add workstation::linux::set_hostname || softfail || return $?

  if [ -d "${HOME}/.runag/.virt-deploy-keys" ]; then
    task::add workstation::linux::deploy_virt_keys || softfail || return $?
  fi


  # development
  task::add --header "Development" || softfail || return $?

  task::add workstation::remove_nodejs_and_ruby_installations || softfail || return $?
  task::add workstation::merge_editor_configs || softfail || return $?
  task::add git::add_signed_off_by_trailer_in_commit_msg_hook || softfail || return $?


  # runagfiles
  runag::tasks || fail


  # storage
  task::add --header "Storage devices" || softfail || return $?
  task::add workstation::linux::storage::check_root || softfail || return $?


  # benchmark
  task::add --header "Benchmark" || softfail || return $?
  if benchmark::is_available; then
    task::add workstation::linux::run_benchmark || softfail || return $?
  else
    task::add --note "Benchmark is not available" || softfail || return $?
  fi


  # password generator
  task::add --header "Password generator" || softfail || return $?
  task::add workstation::linux::generate_password || softfail || return $?
}


# tasks
task::add --header "Workstation" || softfail || return $?

case "${OSTYPE}" in
  linux*)
    task::add --group workstation::linux::tasks || softfail || return $?
    ;;
esac

task::add --group workstation::identity::tasks || softfail || return $?
task::add --group workstation::key_storage::tasks || softfail || return $?

task::add --group --os linux workstation::backup::tasks || softfail || return $?
task::add --group --os linux workstation::repositories_backup::tasks || softfail || return $?
