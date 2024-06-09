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
# source::related_to_file "${BASH_SOURCE[0]}" "config.sh" || softfail || return $?

# load all shell files
source::recursive_related_to_file "${BASH_SOURCE[0]}" "lib" || softfail || return $?

# menu
menu::add --header "Workstation" || softfail || return $?

menu::add --menu workstation::deployment::menu || softfail || return $?
menu::add --menu workstation::identity::menu || softfail || return $?
menu::add --menu workstation::key_storage::menu || softfail || return $?

menu::add --menu --os linux workstation::backup::menu || softfail || return $?
menu::add --menu --os linux workstation::remote_repositories_backup::menu || softfail || return $?
