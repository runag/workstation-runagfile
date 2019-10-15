#!/usr/bin/env bash

#  Copyright 2012-2016 Stanislav Senotrusov <stan@senotrusov.com>
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

data-pi::ensure-this-is-raspberry-pi() {
  if [ "$(dpkg --print-architecture)" !=  armhf ]; then
    echo "This has to be an Raspberry Pi ($?)" >&2
    exit 1
  fi
}

data-pi::install-shell-aliases() {
  local outputFile="${HOME}/.bashrc.d/data-pi-shell-aliases.sh"

  if [ ! -f "${outputFile}" ]; then
    deploy-lib::bitwarden::unlock || fail

    local onionAddress; onionAddress="$(bw get password "data-pi onion address")" || fail "Unable to get data-pi onion address"

    local portMappings; portMappings="-q -L 8385:localhost:8384 -L 19998:localhost:19999" || fail
    local torProxy; torProxy="-o ProxyCommand=$(printf "%q" "nc -x localhost:9050 %h %p")" || fail

    local getPassword; getPassword="BW_SESSION=\"\$(bw unlock --raw)\" bw get password $(printf "%q" "${DATA_PI_DISK_KEY}")" || fail

    local unlockCommand; unlockCommand="$(printf "%q" "echo unlocking... && ! { findmnt -M ~/$(printf "%q" "${DATA_PI_DISK_NAME}") >/dev/null && echo already unlocked; } && sudo cryptsetup luksOpen /dev/sda1 $(printf "%q" "${DATA_PI_DISK_NAME}") && sudo fsck -pf /dev/mapper/$(printf "%q" "${DATA_PI_DISK_NAME}") && sudo mount /dev/mapper/$(printf "%q" "${DATA_PI_DISK_NAME}") ~/$(printf "%q" "${DATA_PI_DISK_NAME}") && sudo systemctl start $(printf "%q" "${DATA_PI_SYNCTHING_SERVICE}@${DATA_PI_USER}").service && echo done")" || fail
    local haltCommand; haltCommand="$(printf "%q" "echo halting... && sudo halt")" || fail
    local rebootCommand; rebootCommand="$(printf "%q" "echo rebooting... && sudo reboot")" || fail
    local statusCommand; statusCommand="$(printf "%q" "uptime && date")" || fail

    tee "${outputFile}" <<SHELL || fail "Unable to write file: ${outputFile} ($?)"
      alias data-pi='ssh ${portMappings} ${DATA_PI_USER}@${DATA_PI_LOCAL_ADDRESS}'
      alias data-pi-onion='ssh ${portMappings} ${torProxy} ${DATA_PI_USER}@${onionAddress}'

      alias data-pi-unlock='${getPassword} | ssh ${DATA_PI_USER}@${DATA_PI_LOCAL_ADDRESS} ${unlockCommand}'
      alias data-pi-onion-unlock='${getPassword} | ssh ${torProxy} ${DATA_PI_USER}@${onionAddress} ${unlockCommand}'

      alias data-pi-halt='ssh ${DATA_PI_USER}@${DATA_PI_LOCAL_ADDRESS} ${haltCommand}'
      alias data-pi-onion-halt='ssh ${torProxy} ${DATA_PI_USER}@${onionAddress} ${haltCommand}'

      alias data-pi-reboot='ssh ${DATA_PI_USER}@${DATA_PI_LOCAL_ADDRESS} ${rebootCommand}'
      alias data-pi-onion-reboot='ssh ${torProxy} ${DATA_PI_USER}@${onionAddress} ${rebootCommand}'

      alias data-pi-status='ssh ${DATA_PI_USER}@${DATA_PI_LOCAL_ADDRESS} ${statusCommand}'
      alias data-pi-onion-status='ssh ${torProxy} ${DATA_PI_USER}@${onionAddress} ${statusCommand}'
SHELL
  fi
}

data-pi::install-motd() {
  sudo install --mode=0755 --owner=root --group=root -D -t /etc/update-motd.d data-pi/85-raspberry || fail "Unable to install /etc/update-motd.d/85-raspberry ($?)"
}

data-pi::install-led-heartbeat() {
  sudo install --mode=0644 --owner=root --group=root -D -t /etc/systemd/system data-pi/led-heartbeat.service || fail "Unable to install led-heartbeat.service ($?)"
  sudo install --mode=0755 --owner=root --group=root -D -t /usr/local/bin data-pi/led-heartbeat.sh || fail "Unable to install led-heartbeat.sh ($?)"

  sudo systemctl daemon-reload || fail "Unable to systemctl daemon-reload ($?)"
  sudo systemctl reenable led-heartbeat.service || fail "Unable to systemctl reenable led-heartbeat.service ($?)"
  sudo systemctl start led-heartbeat.service || fail "Unable to systemctl start led-heartbeat.service ($?)"
}

data-pi::apt::add-ubuntu-raspi2-ppa() {
  sudo add-apt-repository --yes ppa:ubuntu-raspi2/ppa || fail "Unable to add-apt-repository ppa:ubuntu-raspi2/ppa ($?)"
}

data-pi::apt::install-packages() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    smartmontools \
    libraspberrypi-bin \
    avahi-daemon || fail "Unable to apt-get install ($?)"
}
