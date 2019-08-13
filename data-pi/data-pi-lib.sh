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
    echo "This has to be an Raspberry Pi (${?})" >&2
    exit 1
  fi
}

data-pi::install-shell-aliases() {
  sudo install --mode=0644 --owner=root --group=root -D -t /etc/profile.d data-pi/data-pi-shell-aliases.sh || fail "Unable to install data-pi-shell-aliases.sh (${?})"
}

data-pi::install-motd() {
  sudo install --mode=0755 --owner=root --group=root -D -t /etc/update-motd.d data-pi/85-raspberry || fail "Unable to install /etc/update-motd.d/85-raspberry (${?})"
}

data-pi::install-led-heartbeat() {
  sudo install --mode=0644 --owner=root --group=root -D -t /etc/systemd/system data-pi/led-heartbeat.service || fail "Unable to install led-heartbeat.service (${?})"
  sudo install --mode=0755 --owner=root --group=root -D -t /usr/local/bin data-pi/led-heartbeat.sh || fail "Unable to install led-heartbeat.sh (${?})"

  sudo systemctl daemon-reload || fail "Unable to systemctl daemon-reload (${?})"
  sudo systemctl reenable led-heartbeat.service || fail "Unable to systemctl reenable led-heartbeat.service (${?})"
  sudo systemctl start led-heartbeat.service || fail "Unable to systemctl start led-heartbeat.service (${?})"
}

data-pi::apt::add-ubuntu-raspi2-ppa() {
  sudo add-apt-repository --yes ppa:ubuntu-raspi2/ppa || fail "Unable to add-apt-repository ppa:ubuntu-raspi2/ppa (${?})"
}

data-pi::apt::install-packages() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    smartmontools \
    libraspberrypi-bin \
    avahi-daemon || fail "Unable to apt-get install (${?})"
}
