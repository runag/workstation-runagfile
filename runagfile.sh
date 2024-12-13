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

# load `config.sh` file first
# shell::related_source config.sh || softfail || return $?

# load all shell files
shell::related_source --recursive lib || softfail || return $?

# tasks
task::add --header "Workstation" || softfail || return $?

case "${OSTYPE}" in
  linux*)
    task::add --group workstation::linux::tasks || softfail || return $?
    ;;
  darwin*)
    task::add --group workstation::macos::tasks || softfail || return $?
    ;; 
esac

task::add --group workstation::identity::tasks || softfail || return $?
task::add --group workstation::key_storage::tasks || softfail || return $?

task::add --group --os linux workstation::backup::tasks || softfail || return $?
task::add --group --os linux workstation::remote_repositories_backup::tasks || softfail || return $?
