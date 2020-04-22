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

deploy::data-pi() {
  . data-pi/data-pi-lib.sh    || fail "Unable to load data-pi/data-pi-lib.sh"
  . netdata/netdata-lib.sh    || fail "Unable to load netdata/netdata-lib.sh"
  . ubuntu/ubuntu-lib.sh      || fail "Unable to load ubuntu/ubuntu-lib.sh"
  . ubuntu/ubuntu-packages.sh || fail "Unable to load ubuntu/ubuntu-packages.sh"

  ubuntu::deploy-data-pi || fail
}

deploy::macos-non-developer-workstation() {
  DEPLOY_NON_DEVELOPER_WORKSTATION=true deploy::macos-workstation || fail
}

deploy::macos-workstation() {
  . data-pi/data-pi-lib.sh  || fail "Unable to load data-pi/data-pi-lib.sh"
  . macos/macos-lib.sh      || fail "Unable to load macos/macos-lib.sh"
  . sublime/sublime-lib.sh  || fail "Unable to load sublime/sublime-lib.sh"
  . vscode/vscode-lib.sh    || fail "Unable to load vscode/vscode-lib.sh"

  macos::deploy-workstation || fail
}

deploy::ubuntu-workstation() {
  . data-pi/data-pi-lib.sh    || fail "Unable to load data-pi/data-pi-lib.sh"
  . sublime/sublime-lib.sh    || fail "Unable to load sublime/sublime-lib.sh"
  . sway/sway-lib.sh          || fail "Unable to load ubuntu/sway.sh"
  . ubuntu/ubuntu-lib.sh      || fail "Unable to load ubuntu/ubuntu-lib.sh"
  . ubuntu/ubuntu-packages.sh || fail "Unable to load ubuntu/ubuntu-packages.sh"
  . vscode/vscode-lib.sh      || fail "Unable to load vscode/vscode-lib.sh"

  ubuntu::deploy-workstation || fail
}

deploy::merge-workstation-configs() {
  . sublime/sublime-lib.sh || fail "Unable to load sublime/sublime-lib.sh"
  . sway/sway-lib.sh       || fail "Unable to load sway/sway-lib.sh"
  . vscode/vscode-lib.sh   || fail "Unable to load vscode/vscode-lib.sh"

  deploy-lib::footnotes::init || fail

  vscode::merge-config || fail
  sublime::merge-config || fail
  sway::merge-config || fail

  deploy-lib::footnotes::flush || fail
}
