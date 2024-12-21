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

workstation::micro::install_config() (
  local config_path; config_path="$(cross_platform::config_home)/micro" || fail
  dir::should_exists --for-me-only "${config_path}" || fail

  relative::cd . || fail

  config::install "bindings.json" "${config_path}/bindings.json" || fail
  config::install "settings.json" "${config_path}/settings.json" || fail
)

workstation::micro::merge_config() (
  local config_path; config_path="$(cross_platform::config_home)/micro" || fail
  dir::should_exists --for-me-only "${config_path}" || fail

  relative::cd . || fail

  config::merge "bindings.json" "${config_path}/bindings.json" || fail
  config::merge "settings.json" "${config_path}/settings.json" || fail
)
