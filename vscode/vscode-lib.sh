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

vscode::snap::install() {
  sudo snap install code --classic || fail "Unable to snap install ($?)"
}

vscode::list-extensions-to-temp-file() {
  local tmpFile; tmpFile="$(mktemp)" || fail "Unable to create temp file"
  code --list-extensions | sort > "${tmpFile}"
  test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to list extensions"
  echo "${tmpFile}"
}

vscode::install-extensions() {
  if [ -f vscode/extensions.txt ]; then
    local extensionsList; extensionsList="$(vscode::list-extensions-to-temp-file)" || fail "Unable get extensions list"

    if ! diff vscode/extensions.txt "${extensionsList}" >/dev/null 2>&1; then
      local extension
      # TODO: how to do correct error handling here (cat | while)?
      cat vscode/extensions.txt | while IFS="" read -r extension; do
        if [ -n "${extension}" ]; then
          code --install-extension "${extension}" || fail "Unable to install vscode extension ${extension}"
        fi
      done
    fi

    rm "${extensionsList}" || fail
  fi

  vscode::sync-merge-extensions-config || fail
}

vscode::sync-merge-extensions-config() {
  local extensionsList; extensionsList="$(vscode::list-extensions-to-temp-file)" || fail "Unable get extensions list"
  deploy-lib::install-config vscode/extensions.txt "${extensionsList}" || fail
  rm "${extensionsList}" || fail
}

vscode::install-config() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    local configDirectory="${HOME}/Library/Application Support/Code"
  else
    local configDirectory="${HOME}/.config/Code"
  fi

  deploy-lib::install-config vscode/settings.json "${configDirectory}/User/settings.json" || fail
  deploy-lib::install-config vscode/keybindings.json "${configDirectory}/User/keybindings.json" || fail
}

vscode::merge-config() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    local configDirectory="${HOME}/Library/Application Support/Code"
  else
    local configDirectory="${HOME}/.config/Code"
  fi

  deploy-lib::merge-config vscode/settings.json "${configDirectory}/User/settings.json" || fail
  deploy-lib::merge-config vscode/keybindings.json "${configDirectory}/User/keybindings.json" || fail

  local extensionsList; extensionsList="$(vscode::list-extensions-to-temp-file)" || fail "Unable get extensions list"
  deploy-lib::merge-config vscode/extensions.txt "${extensionsList}" || fail
}
