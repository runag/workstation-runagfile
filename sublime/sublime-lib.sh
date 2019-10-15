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

sublime::apt::add-sublime-source() {
  curl --fail --silent --show-error https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
  test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to curl https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add"

  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list || fail "Unable to write to /etc/apt/sources.list.d/sublime-text.list"
}

sublime::apt::install-sublime-merge() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    sublime-merge || fail "Unable to apt-get install ($?)"
}

sublime::apt::install-sublime-text() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    sublime-text || fail "Unable to apt-get install ($?)"
}

sublime::install-config() {
  local installedPackages="${HOME}/.config/sublime-text-3/Installed Packages"
  local packageControlPackage="${installedPackages}/Package Control.sublime-package"

  if [ ! -f "${packageControlPackage}" ]; then
    mkdir --parents "${installedPackages}" || fail "Unable to create directory ${installedPackages} ($?)"
    
    curl --fail --silent --show-error "https://packagecontrol.io/Package%20Control.sublime-package" --output "${packageControlPackage}.tmp" || fail "Unable to download https://packagecontrol.io/Package%20Control.sublime-package ($?)"

    mv "${packageControlPackage}.tmp" "${packageControlPackage}" || fail "Unable to rename temp file to${packageControlPackage}"
  fi

  sublime::install-config-file "Preferences.sublime-settings" || fail "Unable to install Preferences.sublime-settings ($?)"
  sublime::install-config-file "Package Control.sublime-settings" || fail "Unable to install Package Control.sublime-settings ($?)"
  sublime::install-config-file "Terminal.sublime-settings" || fail "Unable to install Terminal.sublime-settings ($?)"

  deploy-lib::bitwarden::write-notes-to-file-if-not-exists "Sublime Text 3 license" "${HOME}/.config/sublime-text-3/Local/License.sublime_license" || fail
}

sublime::merge-config() {
  sublime::merge-config-file "Preferences.sublime-settings" || fail
  sublime::merge-config-file "Package Control.sublime-settings" || fail
  sublime::merge-config-file "Terminal.sublime-settings" || fail
}

sublime::install-config-file() {
  deploy-lib::install-config "sublime/$1" "${HOME}/.config/sublime-text-3/Packages/User/$1" || fail "Unable to install $1 ($?)"
}

sublime::merge-config-file() {
  deploy-lib::merge-config "sublime/$1" "${HOME}/.config/sublime-text-3/Packages/User/$1" || fail "Unable to merge $1 ($?)"
}
