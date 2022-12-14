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

workstation::identity::menu() {
  runagfile_menu::display_for workstation::identity::runagfile_menu
  fail_unless_good_code $?
}

workstation::identity::runagfile_menu() {
  runagfile_menu::add --header "Workstation identity" || fail

  runagfile_menu::add workstation::use_identity identity/personal || fail
}
