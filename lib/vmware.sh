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

workstation::vmware::use_hgfs_mounts() {
  workstation::vmware::add_hgfs_automount || softfail || return $?
  workstation::vmware::symlink_hgfs_mounts || softfail || return $?
}

workstation::vmware::add_hgfs_automount() {
  local mount_point="${1:-"/mnt/hgfs"}"

  # https://askubuntu.com/a/1051620
  # TODO: Do I really need x-systemd.device-timeout here? think it works well even without it.
  # TODO: file::read_with_updated_block /etc/fstab HGFS_AUTOMOUNT | fstab::verify_and_write
  if ! grep -qF "fuse.vmhgfs-fuse" /etc/fstab; then
    echo ".host:/  ${mount_point}  fuse.vmhgfs-fuse  defaults,allow_other,uid=1000,nofail,x-systemd.device-timeout=1s  0  0" | sudo tee -a /etc/fstab >/dev/null || softfail "Unable to write to /etc/fstab ($?)" || return $?
  fi
}

workstation::vmware::symlink_hgfs_mounts() {
  local mount_point="/mnt/hgfs"
  local symlinks_directory="${HOME}"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -m|--mount-point)
        mount_point="$2"
        shift; shift
        ;;
      -s|--symlinks-directory)
        symlinks_directory="$2"
        shift; shift
        ;;
      -*)
        softfail "Unknown argument: $1" || return $?
        ;;
      *)
        break
        ;;
    esac
  done

  if findmnt --mountpoint "${mount_point}" >/dev/null; then
    local dir_path dir_name
    # I use find here because for..in did not work with hgfs
    find "${mount_point}" -maxdepth 1 -mindepth 1 -type d | while IFS="" read -r dir_path; do
      dir_name="$(basename "${dir_path}")" || softfail || return $?
      if [ ! -e "${symlinks_directory}/${dir_name}" ]; then
        ln --symbolic "${dir_path}" "${symlinks_directory}/${dir_name}" || softfail "unable to create symlink to ${dir_path}" || return $?
      fi
    done
  fi
}

workstation::vmware::get_host_ip_address() {
  local ip_address; ip_address="$(ip route get 1.1.1.1 | sed -n 's/^.*via \([[:digit:].]*\).*$/\1/p' | sed 's/[[:digit:]]\+$/1/'; test "${PIPESTATUS[*]}" = "0 0 0")" || softfail "Unable to obtain host ip address" || return $?
  if [ -z "${ip_address}" ]; then
    softfail "Unable to obtain host ip address" || return $?
  fi
  echo "${ip_address}"
}

workstation::vmware::vm_network_loss_workaround() {
  if ip address show ens33 >/dev/null 2>&1; then
    if ! ip address show ens33 | grep -qF "inet "; then
      echo "workstation::vmware::vm_network_loss_workaround: about to restart network"
      sudo systemctl restart NetworkManager.service || fail "Unable to restart network"
      sudo dhclient || fail "Error running dhclient"
    fi
  fi
}

workstation::vmware::install_vm_network_loss_workaround() {
  temp_file="$(mktemp)" || fail
  {
    runag::mini_library || fail

    declare -f workstation::vmware::vm_network_loss_workaround || fail

    echo 'set -o nounset'
    echo 'workstation::vmware::vm_network_loss_workaround || fail'

  } >"${temp_file}" || fail

  file::write --absorb "${temp_file}" --sudo --mode 0755 /usr/local/bin/vmware-vm-network-loss-workaround || softfail || return $?

  file::write --sudo --mode 0644 /etc/systemd/system/vmware-vm-network-loss-workaround.service <<EOF || softfail || return $?
[Unit]
Description=vmware-vm-network-loss-workaround

[Service]
Type=oneshot
ExecStart=/usr/local/bin/vmware-vm-network-loss-workaround
WorkingDirectory=/
EOF

  file::write --sudo --mode 0644 /etc/systemd/system/vmware-vm-network-loss-workaround.timer <<EOF || softfail || return $?
[Unit]
Description=vmware-vm-network-loss-workaround

[Timer]
OnCalendar=minutely
Persistent=true

[Install]
WantedBy=timers.target
EOF

  sudo systemctl --quiet reenable vmware-vm-network-loss-workaround.timer || softfail || return $?
  sudo systemctl start vmware-vm-network-loss-workaround.timer || softfail || return $?
}
