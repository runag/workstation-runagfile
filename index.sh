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

# fs::source_related_to_file "${BASH_SOURCE[0]}" "config.sh" || fail

fs::source_recursive_related_to_file "${BASH_SOURCE[0]}" "lib" || fail


# menu
runagfile_menu::add --header "Workstation" || fail

runagfile_menu::add workstation::deployment::menu || fail
runagfile_menu::add workstation::key_storage::menu || fail
runagfile_menu::add workstation::identity::menu || fail
runagfile_menu::add --os linux workstation::backup::menu || fail
runagfile_menu::add --os linux workstation::remote_repositories_backup::menu || fail
runagfile_menu::add workstation::tools::menu || fail
