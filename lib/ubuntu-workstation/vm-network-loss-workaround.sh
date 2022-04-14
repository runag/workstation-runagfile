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

ubuntu_workstation::vm_network_loss_workaround() {
  if ip address show ens33 >/dev/null 2>&1; then
    if ! ip address show ens33 | grep -qF "inet "; then
      echo "ubuntu_workstation::vm_network_loss_workaround: about to restart network"
      sudo systemctl restart NetworkManager.service || { echo "Unable to restart network" >&2; exit 1; }
      sudo dhclient || { echo "Error running dhclient" >&2; exit 1; }
    fi
  fi
}

ubuntu_workstation::install_vm_network_loss_workaround() {
  file::sudo_write /usr/local/bin/vm-network-loss-workaround 755 <<SHELL || fail
#!/usr/bin/env bash
$(sopka::print_license)
$(declare -f ubuntu_workstation::vm_network_loss_workaround)
ubuntu_workstation::vm_network_loss_workaround || { echo "Unable to perform ubuntu_workstation::vm_network_loss_workaround" >&2; exit 1; }
SHELL

  file::sudo_write /etc/systemd/system/vm-network-loss-workaround.service <<EOF || fail
[Unit]
Description=vm-network-loss-workaround

[Service]
Type=oneshot
ExecStart=/usr/local/bin/vm-network-loss-workaround
WorkingDirectory=/
EOF

  file::sudo_write /etc/systemd/system/vm-network-loss-workaround.timer <<EOF || fail
[Unit]
Description=vm-network-loss-workaround

[Timer]
OnCalendar=minutely
Persistent=true

[Install]
WantedBy=timers.target
EOF

  sudo systemctl --quiet reenable vm-network-loss-workaround.timer || fail
  sudo systemctl start vm-network-loss-workaround.timer || fail
}
