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

task::add workstation::linux::deploy_workstation || softfail || return $?
task::add workstation::linux::set_hostname || softfail || return $?

if benchmark::is_available; then
  task::add workstation::linux::run_benchmark || softfail || return $?
fi

task::add workstation::linux::storage::check_root || softfail || return $?
task::add workstation::linux::generate_password || softfail || return $?

task::add workstation::merge_editor_configs || softfail || return $?
task::add git::add_signed_off_by_trailer_in_commit_msg_hook || softfail || return $?

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

# Config
workstation::get_config_dir() {
  local full_path="${XDG_CONFIG_HOME:-"${HOME}/.config"}/workstation-runagfile${1:+"/$1"}"

  dir::ensure_exists --user-only "${full_path}" || fail

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

# Adds tasks to perform the upsert and update operations for the cold rùnag repository.
task::add cold_deploy::update || softfail || return $?
task::add cold_deploy::upsert || softfail || return $?

# ### `cold_deploy::update`
#
# This function updates the cold (offline) Rùnag deployment repository.
#
# It performs the following tasks:
# - Verifies that the cold Rùnag repository exists.
# - Retrieves the offline installation URL from the Rùnag configuration.
# - Calls `cold_deploy::upsert` to update the repository with the retrieved URL.
#
# #### Parameters: None
#
cold_deploy::update() {
  local runag_path="${HOME}/.runag"

  # Check if the Rùnag repository exists.
  if [ ! -d "${runag_path}/.git" ]; then
    softfail "Unable to find Rùnag checkout in the specified directory: ${runag_path}" || return $?
  fi

  # Retrieve the remote offline installation URL from the Rùnag configuration.
  local remote_path; remote_path="$(git -C "${runag_path}" config "remote.offline-install.url")" || softfail "Failed to retrieve remote URL for offline installation." || return $?

  # Call the upsert function to update the repository and its contents.
  cold_deploy::upsert "${remote_path}/.." || softfail "Failed to upsert the Rùnag repository with remote path: ${remote_path}" || return $?
}

# ### `cold_deploy::upsert`
#
# This function performs an "upsert" operation on the cold (offline) Rùnag repository.
# If a target path is provided, the function changes to that directory and attempts
# to update the repository by pulling and pushing changes.
#
# It performs the following tasks:
# - Changes to the provided remote path (if specified).
# - Verifies the existence of the Rùnag repository.
# - Retrieves the remote URL of the repository and performs pull and push operations.
# - Creates or updates mirrors for the repository and fetches the latest updates.
# - Updates all subdirectories within "runagfiles" by performing similar operations on each.
# - Copies the deploy script to the current working directory.
#
# #### Parameters:
# - `$1`: Optional target path. If provided, the script changes to that directory before performing operations.
#
cold_deploy::upsert() (
  local runag_path="${HOME}/.runag"

  # If a remote path is provided, change to that directory.
  if [ -n "${1:-}" ]; then
    cd "$1" || softfail "Failed to change directory to: $1" || return $?
  fi

  local target_directory="${PWD}" || softfail "Failed to determine current working directory." || return $?

  # Ensure the Rùnag repository exists.
  if [ ! -d "${runag_path}/.git" ]; then
    softfail "Unable to find Rùnag checkout in the specified directory: ${runag_path}" || return $?
  fi

  # Retrieve the remote URL of the Rùnag repository.
  local runag_remote_url; runag_remote_url="$(git -C "${runag_path}" remote get-url origin)" || softfail "Failed to retrieve remote URL for Rùnag repository." || return $?

  # Pull the latest changes from the main branch and push to the remote.
  git -C "${runag_path}" pull origin main || softfail "Failed to pull changes from the main branch of Rùnag repository." || return $?
  git -C "${runag_path}" push --set-upstream origin main || softfail "Failed to push changes to the main branch of Rùnag repository." || return $?

  # Create or update the mirror for the Rùnag repository.
  git::create_or_update_mirror "${runag_remote_url}" runag.git || softfail "Failed to create or update mirror for Rùnag repository." || return $?

  # Update the offline install remote.
  ( cd "${runag_path}" && git::add_or_update_remote "offline-install" "${target_directory}/runag.git" && git fetch "offline-install" ) || softfail "Failed to add or update offline-install remote for Rùnag repository." || return $?

  # Ensure that the 'runagfiles' directory exists with the correct permissions.
  dir::ensure_exists --mode 0700 "runagfiles" || softfail "Unable to ensure the existence and correct permissions of 'runagfiles'." || return $?

  # Iterate through each subdirectory within 'runagfiles' and perform updates.
  local runagfile_path; for runagfile_path in "${runag_path}/runagfiles"/*; do
    if [ -d "${runagfile_path}" ]; then
      local runagfile_dir_name; runagfile_dir_name="$(basename "${runagfile_path}")" || softfail "Failed to determine directory name for: ${runagfile_path}" || return $?
      local runagfile_remote_url; runagfile_remote_url="$(git -C "${runagfile_path}" remote get-url origin)" || softfail "Failed to retrieve remote URL for 'runagfile' directory: ${runagfile_path}" || return $?

      # Perform pull and push operations for each subdirectory.
      git -C "${runagfile_path}" pull origin main || softfail "Failed to pull changes from the main branch of 'runagfile' directory: ${runagfile_path}" || return $?
      git -C "${runagfile_path}" push --set-upstream origin main || softfail "Failed to push changes to the main branch of 'runagfile' directory: ${runagfile_path}" || return $?

      # Create or update the mirror for each 'runagfile' directory.
      git::create_or_update_mirror "${runagfile_remote_url}" "runagfiles/${runagfile_dir_name}" || softfail "Failed to create or update mirror for 'runagfile' directory: ${runagfile_path}" || return $?

      # Update the offline install remote for each subdirectory.
      ( cd "${runagfile_path}" && git::add_or_update_remote "offline-install" "${target_directory}/runagfiles/${runagfile_dir_name}" && git fetch "offline-install" ) || softfail "Failed to add or update offline-install remote for 'runagfile' directory: ${runagfile_path}" || return $?
    fi
  done

  # Copy the deploy script to the current directory.
  cp -f "${runag_path}/deploy-offline.sh" . || softfail "Failed to copy the deploy-offline.sh script." || return $?
)

workstation::set_battery_profile() {
  local profile_function="$1"

  local temp_file; temp_file="$(mktemp)" || fail
  {
    runag::mini_library --nounset || fail

    declare -f linux::set_battery_charge_control_threshold || fail
    declare -f "${profile_function}" || fail

    printf '%q || fail' "${profile_function}" || fail

  } >"${temp_file}" || fail

  file::write --consume "${temp_file}" --root --mode 755 /usr/local/bin/set-workstation-battery-profile || fail

  file::write --root /etc/systemd/system/set-workstation-battery-profile.service <<EOF || fail
[Unit]
Description=Update battery profile

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-workstation-battery-profile

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl --quiet --now enable "set-workstation-battery-profile.service" || fail
}
