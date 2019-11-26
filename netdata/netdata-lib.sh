#!/usr/bin/env bash

#  Copyright 2012-2019 Stanislav Senotrusov <stan@senotrusov.com>
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

netdata::install() {
  if [ ! -d /etc/netdata ]; then
    bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait --stable-channel || true # TODO: remove || true as they fix the installer
  fi
}

netdata::configure() {
  sudo install --mode=0644 --owner=root --group=root -D -t /etc/netdata netdata/netdata.conf || fail "Unable to install netdata/netdata.conf ($?)"
  sudo install --mode=0644 --owner=root --group=root -D -t /etc/netdata/python.d netdata/python.d/postgres.conf || fail "Unable to install netdata/python.d/postgres.conf ($?)"
  sudo systemctl restart netdata || fail "Unable to run systemctl restart ($?)"
}
