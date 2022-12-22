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

workstation::use_identity() {(
  local set_global identity_name directory_path

  while [[ "$#" -gt 0 ]]; do
    case $1 in
    -g|--global)
      set_global=true
      shift
      ;;
    -n|--name)
      identity_name="$2"
      shift; shift
      ;;
    -d|--dir)
      directory_path="$2"
      shift; shift
      ;;
    -*)
      fail "Unknown argument: $1"
      ;;
    *)
      break
      ;;
    esac
  done

  local identity_path="$1"

  local identity_name="${identity_name:-"$(basename "${identity_path}")"}" || fail

  if [ -n "${directory_path:-}" ]; then
    cd "${directory_path}" || fail
  fi

  # ssh
  if pass::exists "${identity_path}/ssh"; then
    ssh::add_ssh_config_d_include_directive || fail
    ssh::install_ssh_profile_from_pass "${identity_path}/ssh" "identity-${identity_name}" || fail
  fi

  # git
  if pass::exists "${identity_path}/git"; then
    git::install_profile_from_pass "${identity_path}/git" ${set_global:+"--global"} || fail
  fi

  # github
  if pass::exists "${identity_path}/github"; then
    github::install_profile_from_pass "${identity_path}/github" || fail
  fi

  # npm
  if pass::exists "${identity_path}/npm/access-token"; then # password field
    asdf::load_if_installed || fail
    if [ "${set_global:-}" = true ]; then
      pass::use "${identity_path}/npm/access-token" npm::auth_token || fail
    elif [ -f package.json ]; then
      pass::use "${identity_path}/npm/access-token" npm::auth_token --project || fail
    fi
  fi

  # rubygems
  if pass::exists "${identity_path}/rubygems/credentials"; then # password field
    if [ "${set_global:-}" = true ]; then
      dir::make_if_not_exists "${HOME}/.gem" 755 || fail
      pass::use "${identity_path}/rubygems/credentials" rubygems::credentials || fail
    elif [ -f Gemfile ]; then
      pass::use "${identity_path}/rubygems/credentials" rubygems::direnv_credentials || fail
    fi
  fi
)}
