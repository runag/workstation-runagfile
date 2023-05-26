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
  local identity_name directory_path as_needed as_default should_confirm

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -i|--identity-name)
        identity_name="$2"
        shift; shift
        ;;
      -d|--for-dir|--for-directory)
        directory_path="$2"
        shift; shift
        ;;
      -n|--as-needed)
        as_needed=true
        shift
        ;;
      -t|--as-default)
        as_default=true
        shift
        ;;
      -c|--confirm)
        should_confirm=true
        shift
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
  
  if [ "${should_confirm:-}" = true ]; then
    echo "You are about to import identity \"${identity_name}\" from: ${identity_path}"

    echo "Please confirm that it is your intention to do so by entering \"yes\""
    echo "Please prepare the password if needed"
    echo "Please enter \"no\" if you want to continue without it being imported."

    local action; IFS="" read -r action || fail

    if [ "${action}" = no ]; then
      echo "Identity is ignored"
      return
    fi

    if [ "${action}" != yes ]; then
      fail
    fi
  fi

  # ssh
  if pass::exists "${identity_path}/ssh"; then
    ssh::add_ssh_config_d_include_directive || fail
    ssh::install_ssh_profile_from_pass "${identity_path}/ssh" "identity-${identity_name}" || fail
  fi

  # github
  if pass::exists "${identity_path}/github"; then
    github::install_profile_from_pass "${identity_path}/github" || fail
  fi

  if [ "${as_needed:-}" = true ]; then
    return
  fi

  if [ "${as_default:-}" = true ]; then
    # git
    if pass::exists "${identity_path}/git"; then
      git::install_profile_from_pass "${identity_path}/git" --global || fail
    fi

    # npm
    if pass::exists "${identity_path}/npm/access-token"; then # password field
      asdf::load_if_installed || fail
      pass::use "${identity_path}/npm/access-token" npm::auth_token || fail
    fi

    # rubygems
    if pass::exists "${identity_path}/rubygems/credentials"; then # password field
      dir::should_exists --mode 0700 "${HOME}/.gem" || fail
      pass::use "${identity_path}/rubygems/credentials" rubygems::credentials || fail
    fi
  else
    # git
    if [ -d .git ] && pass::exists "${identity_path}/git"; then
      git::install_profile_from_pass "${identity_path}/git" || fail
    fi

    # npm
    if [ -f package.json ] && pass::exists "${identity_path}/npm/access-token"; then # password field
      asdf::load_if_installed || fail
      pass::use "${identity_path}/npm/access-token" npm::auth_token --project || fail
    fi

    # rubygems
    if [ -f Gemfile ] && pass::exists "${identity_path}/rubygems/credentials"; then # password field
      pass::use "${identity_path}/rubygems/credentials" rubygems::direnv_credentials || fail
    fi
  fi
)}
