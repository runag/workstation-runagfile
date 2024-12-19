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

task::add --group workstation::identity::tasks || softfail || return $?

workstation::identity::tasks::set() {
  # Configure identity and install credentials for use in project that resides in current directory: ${PWD} (task header)
  if [ -d .git ] || [ -f package.json ] || [ -f Gemfile ]; then
    workstation::identity::tasks::list --for-directory . || fail
  else
    # No project found in current directory (task note)
    true
  fi

  # Configure identity and install credentials (task header)
  workstation::identity::tasks::list --with-system-credentials || fail

  # Configure identity, install credentials, and set default credentials (task header)
  workstation::identity::tasks::list --with-system-credentials --as-default || fail
}

workstation::identity::tasks::list() {
  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  local identity_found=false

  local absolute_identity_path; for absolute_identity_path in "${password_store_dir}/identity"/* ; do
    if [ -d "${absolute_identity_path}" ]; then
      local identity_path="${absolute_identity_path:$((${#password_store_dir}+1))}"
      local git_user_name=""

      if pass::exists "${identity_path}/git/user-name"; then
        git_user_name="$(pass::use "${identity_path}/git/user-name")" || fail
      fi

      task::add ${git_user_name:+"--comment" "${git_user_name}"} workstation::identity::use "$@" "${identity_path}" || softfail || return $?

      identity_found=true
    fi
  done

  if [ "${identity_found}" = false ]; then
    # No identities found in password store (task note)
    true
  fi
}

workstation::identity::use() {
  local identity_name directory_path
  local with_system_credentials=false as_default=false should_confirm=false

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -c|--confirm)
        should_confirm=true
        shift
        ;;
      -d|--for-dir|--for-directory)
        directory_path="$2"
        shift; shift
        ;;
      -i|--identity-name)
        identity_name="$2"
        shift; shift
        ;;
      -s|--with-system-credentials)
        with_system_credentials=true
        shift
        ;;
      -t|--as-default)
        as_default=true
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

  if [ "${should_confirm}" = true ]; then
    echo ""
    echo "You are about to import identity \"${identity_name}\" from: ${identity_path}"
    echo ""
    echo "Please confirm that it is your intention to do so by entering \"yes\""
    echo "Please prepare the password if needed"
    echo "Please enter \"no\" if you want to continue without it being imported."

    if ! ui::confirm; then
      log::warning "Identity was not imported" || fail
      return 0
    fi
  fi

  # ssh
  if pass::exists "${identity_path}/ssh"; then
    ssh::add_ssh_config_d_include_directive || fail
    ssh::install_ssh_profile_from_pass --profile-name "identity-${identity_name}" "${identity_path}/ssh" || fail
  fi

  # github
  if pass::exists "${identity_path}/github"; then
    github::install_profile_from_pass "${identity_path}/github" || fail
  fi

  # runagfiles
  if pass::exists "${identity_path}/runag/runagfiles"; then
    workstation::add_runagfiles "${identity_path}/runag/runagfiles" || fail
  fi

  if [ -n "${directory_path:-}" ]; then
    (
      cd "${directory_path}" || fail

      # git
      if [ -d .git ] && pass::exists "${identity_path}/git"; then
        git::install_profile_from_pass "${identity_path}/git" || fail
      fi

      # npm
      if [ -f package.json ] && pass::exists "${identity_path}/npm/access-token"; then # password field
        asdf::load --if-installed || fail
        pass::use "${identity_path}/npm/access-token" npm::auth_token --project || fail
      fi

      # rubygems
      if [ -f Gemfile ] && pass::exists "${identity_path}/rubygems/credentials"; then # password field
        pass::use "${identity_path}/rubygems/credentials" rubygems::direnv_credentials || fail
      fi
    ) || fail
  fi

  if [ "${with_system_credentials}" = true ]; then
    # setup tailscale
    if pass::exists "${identity_path}/tailscale/authkey"; then
      workstation::connect_tailscale "${identity_path}/tailscale/authkey" || fail
    fi

    # install sublime merge license
    if pass::exists "${identity_path}/sublime-merge/license"; then
      workstation::sublime_merge::install_license "${identity_path}/sublime-merge/license" || fail
    fi

    # install sublime text license
    if pass::exists "${identity_path}/sublime-text/license"; then
      workstation::sublime_text::install_license "${identity_path}/sublime-text/license" || fail
    fi

    # setup ubuntu pro subscription
    if ubuntu::pro::available && pass::exists "${identity_path}/ubuntu-pro/token" && ! ubuntu::pro::is_attached; then
      pass::use "${identity_path}/ubuntu-pro/token" sudo pro attach || fail
    fi

    # connect to wifi
    if pass::exists "${identity_path}/wifi" && wifi::is_available && ! wifi::is_connected; then
      wifi::connect --pass-path "${identity_path}/wifi" || fail
    fi
  fi

  if [ "${as_default}" = true ]; then
    # git
    if pass::exists "${identity_path}/git"; then
      git::install_profile_from_pass "${identity_path}/git" --global || fail
    fi

    # npm
    if pass::exists "${identity_path}/npm/access-token"; then # password field
      asdf::load --if-installed || fail
      pass::use "${identity_path}/npm/access-token" npm::auth_token || fail
    fi

    # rubygems
    if pass::exists "${identity_path}/rubygems/credentials"; then # password field
      dir::should_exists --mode 0700 "${HOME}/.gem" || fail
      pass::use "${identity_path}/rubygems/credentials" rubygems::credentials || fail
    fi
  fi
}
