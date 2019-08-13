#!/bin/bash

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

sublime::install-sublime-merge() {
  curl --fail --silent --show-error https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
  test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to curl https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add"

  sudo apt-get install -o Acquire::ForceIPv4=true apt-transport-https || fail "Unable to apt-get install ($?)"

  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
  test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to wrote to /etc/apt/sources.list.d/sublime-text.list"

  sudo apt-get -o Acquire::ForceIPv4=true update || fail "Unable to apt-get update ($?)"

  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    sublime-merge || fail "Unable to apt-get install ($?)"
}

sublime::install-sublime-text() {
  curl --fail --silent --show-error https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -

  sudo apt-get install -o Acquire::ForceIPv4=true apt-transport-https

  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

  sudo apt-get -o Acquire::ForceIPv4=true update

  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    sublime-text
}

sublime::configure-sublime-text() {
  local installedPackages="$HOME/.config/sublime-text-3/Installed Packages"

  local packageControlPackage="$installedPackages/Package Control.sublime-package"

  if [ ! -f "$packageControlPackage" ]; then
    mkdir --parents "$installedPackages"
    curl --fail --silent --show-error "https://packagecontrol.io/Package%20Control.sublime-package" --output "$packageControlPackage.tmp"
    mv "$packageControlPackage.tmp" "$packageControlPackage"
  fi

  sublime::install-sublime-text-preferences "Preferences.sublime-settings"
  sublime::install-sublime-text-preferences "Package Control.sublime-settings"
  sublime::install-sublime-text-preferences "Terminal.sublime-settings"
}

sublime::install-sublime-text-preferences() {
  local fileName="$1"

  local userPackage="$HOME/.config/sublime-text-3/Packages/User"
  mkdir --parents "$userPackage"

  local source="sublime/$fileName"
  local dest="$userPackage/$fileName"

  if [ -f "$source" ] && [ ! -f "$dest" ]; then
    install --mode=0644 "$source" "$dest"
  fi
}
