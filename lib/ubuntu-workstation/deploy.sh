#!/usr/bin/env bash

#  Copyright 2012-2022 Stanislav Senotrusov <stan@senotrusov.com>
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

ubuntu_workstation::deploy_workstation() {
  ubuntu_workstation::deploy_workstation_without_secrets || fail

  ubuntu_workstation::deploy_secrets || fail
  
  task::run_with_install_filter ubuntu_workstation::backup::deploy || fail
  task::run_with_install_filter ubuntu_workstation::github_repositories_backup::deploy || fail

  if vmware::is_inside_vm; then
    task::run_with_install_filter ubuntu_workstation::deploy_host_folders_access || fail
  fi

  task::run_with_install_filter ubuntu_workstation::deploy_tailscale || fail
}

ubuntu_workstation::deploy_workstation_with_opionated_configuration() {
  ubuntu_workstation::deploy_workstation || fail
  ubuntu_workstation::deploy_opionated_configuration || fail
}

ubuntu_workstation::deploy_workstation_without_secrets() {
  task::run_with_install_filter ubuntu_workstation::deploy_software_packages || fail
  task::run_with_install_filter ubuntu_workstation::deploy_configuration || fail
}

ubuntu_workstation::deploy_secrets() {
  workstation::deploy_secrets || fail
}

ubuntu_workstation::deploy_host_folders_access() {
  # install cifs-utils
  apt::install cifs-utils || fail

  # get user name
  local username; username="$(pass::use "${MY_WINDOWS_CIFS_CREDENTIALS_PATH}" --get username)" || fail

  # write credentials to local filesystem
  local credentials_file="${MY_KEYS_PATH}/host-filesystem-access.cifs-credentials"

  workstation::make_keys_directory_if_not_exists || fail
  
  pass::use "${MY_WINDOWS_CIFS_CREDENTIALS_PATH}" cifs::credentials "${credentials_file}" "${username}" || fail

  # get host ip address
  local remote_host; remote_host="$(vmware::get_host_ip_address)" || fail

  # mount host folder
  REMOTE_HOST="${remote_host}" CREDENTIALS_FILE="${credentials_file}" ubuntu_workstation::mount_host_folders || fail
}

# shellcheck disable=2153
ubuntu_workstation::mount_host_folder() {
  cifs::mount "//${REMOTE_HOST}/$1" "${HOME}/${2:-"$1"}" "${CREDENTIALS_FILE}" || fail
}

ubuntu_workstation::mount_host_folders() {
  ubuntu_workstation::mount_host_folder "my" || fail
  ubuntu_workstation::mount_host_folder "ephemeral-data" || fail
}

ubuntu_workstation::deploy_tailscale() {
  # install tailscale
  if ! command -v tailscale >/dev/null; then
    tailscale::install || fail
  fi

  if vmware::is_inside_vm; then
    # https://github.com/tailscale/tailscale/issues/2541
    tailscale::install_issue_2541_workaround || fail
  fi

  # logout if SOPKA_UPDATE_SECRETS is set
  if [ "${SOPKA_UPDATE_SECRETS:-}" = true ] && tailscale::is_logged_in; then
    sudo tailscale logout || fail
  fi

  if ! tailscale::is_logged_in; then
    local tailscale_key; tailscale_key="$(pass::use "${MY_TAILSCALE_REUSABLE_KEY_PATH}")" || fail
    sudo tailscale up --authkey "${tailscale_key}" || fail  
  fi
}

ubuntu_workstation::deploy_vm_server() {
  # remove unattended-upgrades
  apt::remove unattended-upgrades || fail

  # perform autoremove, update and upgrade
  apt::autoremove_lazy_update_and_maybe_dist_upgrade || fail

  # install open-vm-tools
  if vmware::is_inside_vm; then
    apt::install open-vm-tools || fail
  fi

  # install and configure sshd
  sshd::disable_password_authentication || fail
  apt::install openssh-server || fail
  sudo systemctl --quiet --now enable ssh || fail
  sudo systemctl reload ssh || fail

  # import ssh key
  apt::install ssh-import-id || fail
  ssh-import-id "gh:${MY_GITHUB_LOGIN}" || fail

  # install avahi daemon
  apt::install avahi-daemon || fail
}
