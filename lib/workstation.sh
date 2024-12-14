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

# one command to encompass the whole workstation deployment process.
workstation::linux::deploy_workstation() {
  # install packages & configure
  workstation::linux::install_packages || fail
  workstation::linux::configure || fail

  # deploy keys
  local mounts_path; mounts_path="$(linux::user_media_path)" || fail
  local key_path="${mounts_path}/workstation-sync"
  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  if [ -d "${key_path}" ]; then
    workstation::linux::deploy_keys "${key_path}" || fail

  elif [ -d "${HOME}/.runag/.virt-deploy-keys" ]; then
    workstation::linux::deploy_virt_keys || fail
  
  elif [ ! -d "${password_store_dir}" ]; then
    fail "Unable to deploy keys: source location not found"
  fi
 
  # deploy identities & credentials
  workstation::linux::deploy_identities || fail

  # setup backup
  workstation::backup::deploy || fail

  # fix for nvidia gpu
  # only if device is present and driver is installed (maybe there is a better method to check that other than "nvidia-smi" presence)
  if nvidia::is_device_present && command -v nvidia-smi >/dev/null; then
    nvidia::enable_preserve_video_memory_allocations || fail
  fi
}

workstation::linux::deploy_keys() {
  local mounts_path; mounts_path="$(linux::user_media_path)" || fail
  local key_storage_volume="${mounts_path}/workstation-sync"

  # install gpg keys
  workstation::key_storage::maintain_checksums --skip-backups --verify-only "${key_storage_volume}" || fail

  local gpg_key_path; for gpg_key_path in "${key_storage_volume}/keys/workstation/gpg"/* ; do
    if [ -d "${gpg_key_path}" ]; then
      local gpg_key_id; gpg_key_id="$(basename "${gpg_key_path}")" || fail

      workstation::key_storage::import_gpg_key "${gpg_key_id}" "${gpg_key_path}/secret-subkeys.asc" || fail
    fi
  done

  # install password store
  workstation::key_storage::password_store_git_remote_clone_or_update_to_local keys/workstation "${key_storage_volume}/keys/workstation/password-store" || fail
}

workstation::linux::deploy_virt_keys() (
  pack() {
    if [ -d "${HOME}/.$1" ]; then
      tar -czf ".virt-deploy-keys/$1.tgz" -C "${HOME}" ".$1"
    fi
  }

  unpack() {
    if [ -f ".virt-deploy-keys/$1.tgz" ]; then
      if [ -d "${HOME}/.$1" ]; then
        local temp_dir; temp_dir="$(mktemp -d "${HOME}/.$1-preceding-XXXXXXXXXX")" || fail
        mv "${HOME}/.$1" "${temp_dir}" || fail
      fi
      tar -xzf ".virt-deploy-keys/$1.tgz" -C "${HOME}" || fail
    fi
  }

  cd "${HOME}/.runag" || fail

  umask 077 || fail

  if ! systemd-detect-virt --quiet; then
    chmod 700 ".virt-deploy-keys" || fail

    pack password-store || fail
    pack gnupg || fail
  
  elif systemd-detect-virt --quiet; then
    unpack password-store || fail
    unpack gnupg || fail
  fi
)

workstation::linux::deploy_identities() {
  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  local absolute_identity_path; for absolute_identity_path in "${password_store_dir}/identity"/* ; do
    if [ -d "${absolute_identity_path}" ]; then
      local identity_path="${absolute_identity_path:$((${#password_store_dir}+1))}"

      workstation::identity::use --with-system-credentials "${identity_path}" || fail
    fi
  done
}

# Runagfiles
workstation::add_runagfiles() {
  local list_path="$1" # should be in the body

  pass::use --body "${list_path}" | runagfile::add_from_list
  test "${PIPESTATUS[*]}" = "0 0" || fail
}


# Cleanup
workstation::remove_nodejs_and_ruby_installations() {
  if asdf plugin list | grep -qFx nodejs; then
    asdf uninstall nodejs || fail
  fi

  if asdf plugin list | grep -qFx ruby; then
    asdf uninstall ruby || fail
  fi

  rm -rf "${HOME}/.nodenv/versions"/* || fail
  rm -rf "${HOME}/.rbenv/versions"/* || fail

  rm -rf "${HOME}/.cache/yarn" || fail
  rm -rf "${HOME}/.solargraph" || fail
  rm -rf "${HOME}/.bundle" || fail
  rm -rf "${HOME}/.node-gyp" || fail
}

# Config
workstation::get_config_dir() {
  local full_path="${XDG_CONFIG_HOME:-"${HOME}/.config"}/workstation-runagfile${1:+"/$1"}"

  dir::should_exists --for-me-only "${full_path}" || fail

  echo "${full_path}"
}

# Editor configs
workstation::merge_editor_configs() {
  workstation::micro::merge_config || fail
  workstation::sublime_merge::merge_config || fail
  workstation::sublime_text::merge_config || fail
  workstation::vscode::merge_config || fail
}

# Connect to tailscale
workstation::connect_tailscale() {
  local key_path="$1" # key sould be in the password

  if ! tailscale::is_logged_in; then
    pass::use "${key_path}" sudo tailscale up --authkey || fail  
  fi
}

workstation::linux::storage::check_root() {
  if [ "$(findmnt --mountpoint / --noheadings --output FSTYPE --raw 2>/dev/null)" != "btrfs" ]; then
    fail "Check on non-btrfs partition is not implemented"
  fi

  local root_device; root_device="$(findmnt --mountpoint / --noheadings --output SOURCE --raw | sed 's/\[\/\@\]$//'; test "${PIPESTATUS[*]}" = "0 0")" || fail

  # "btrfs check --check-data-csum" is not accurate on live filesystem
  sudo btrfs scrub start -B -d "${root_device}" || fail
  sudo btrfs check --readonly --force "${root_device}" || fail
}

workstation::linux::set_hostname() {
  echo "Please keep in mind that the script to change hostname is not perfect, please take time to review the script and it's results"
  echo "Please enter new hostname:"
  
  local hostname; IFS="" read -r hostname || fail

  linux::set_hostname "${hostname}" || fail
}

workstation::linux::run_benchmark() {
  benchmark::run || fail
}

# shellcheck disable=SC2005
workstation::linux::generate_password() {

  # those are non-word characters on US ANSI keyboard:
  # `~!@#$%^&*()-_=+[{]}\|;:'",<.>/?
  #
  # a-zA-Z0-9 is 62 characters
  #
  # calculate in ruby:
  # 
  # Math.log2((62 + 7) ** 42) = 256 bits of entropy
  # Math.log2((62 + 23) ** 20) = 128 bits of entropy

  echo "42 symbols, 256 bits of entropy:"
  LC_ALL=C tr -dc 'a-zA-Z0-9!@#$\-=?' </dev/urandom | head -c 42 # 256

  printf "\n\n21 symbols, 128 bits of entropy:\n"
  LC_ALL=C tr -dc 'a-zA-Z0-9!@#$\-=?' </dev/urandom | head -c 21 # 128

  printf "\n\n22 symbols, 128 bits of entropy, no special characters:\n"
  LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 22 # 128

  printf "\n\n20 symbols, 128 bits of entropy (with more variety of non-word characters):\n"
  LC_ALL=C tr -dc 'a-zA-Z0-9!@#$%^&*()\-=[{]}\\:<.>/?' </dev/urandom | head -c 20 # 128

  printf "\n"
}
