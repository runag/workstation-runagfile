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

fail() {
  echo "${BASH_SOURCE[1]}:${BASH_LINENO[0]}: in \`${FUNCNAME[1]}': Error: ${1:-"Abnormal termination"}" >&2
  exit "${2:-1}"
}

tools::sudo-write-file() {
  local dest="$1"
  local mode="${2:-0644}"
  local owner="${3:-root}"
  local group="${4:-$owner}"

  local dirName; dirName="$(dirname "${dest}")" || fail "Unable to get dirName of '${dest}' ($?)"

  sudo mkdir -p "${dirName}" || fail "Unable to mkdir -p '${dirName}' ($?)"

  cat | sudo tee "$dest"
  test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to cat or write to '$dest'"

  sudo chmod "$mode" "$dest" || fail "Unable to chmod '${dest}' ($?)"
  sudo chown "$owner:$group" "$dest" || fail "Unable to chown '${dest}' ($?)"
}

tools::install-my-computer-deploy-shell-alias() {
tools::sudo-write-file /etc/profile.d/my-computer-deploy-shell-alias.sh <<SHELL || fail "Unable to write file /etc/profile.d/my-computer-deploy-shell-alias.sh ($?)"
  alias my-computer-deploy="${PWD}/bin/shell"
SHELL
}

tools::make-latest-git-repository-clone-available() {
  local repoUrl="$1"
  local localCloneDir="$2"

  tools::add-host-to-ssh-known-hosts bitbucket.org || fail
  tools::add-host-to-ssh-known-hosts github.com || fail

  if [ ! -d "${localCloneDir}" ]; then
    git clone "${repoUrl}" "${localCloneDir}" || fail "Unable to clone ${repoUrl} into ${localCloneDir}"
  else
    local existingRepoUrl; existingRepoUrl="$(cd "${localCloneDir}" && git config --get remote.origin.url)" || fail "Unable to get existingRepoUrl"

    if [ "${existingRepoUrl}" != "${repoUrl}" ]; then
      rm -rf "${localCloneDir}" || fail "Unable to delete repository ${localCloneDir}"
      git clone "${repoUrl}" "${localCloneDir}" || fail "Unable to clone ${repoUrl} into ${localCloneDir}"
    else
      (cd "${localCloneDir}" && git pull) || fail "Unable to pull from ${repoUrl}"
    fi
  fi
}

tools::add-host-to-ssh-known-hosts() {
  local hostName="$1"
  local knownHosts="${HOME}/.ssh/known_hosts"

  if ! command -v ssh-keygen >/dev/null; then
    fail "ssh-keygen not found"
  fi

  if [ ! -f "${knownHosts}" ]; then
    local knownHostsDirname; knownHostsDirname="$(dirname "${knownHosts}")" || fail

    mkdir -p "${knownHostsDirname}" || fail
    chmod 700 "${knownHostsDirname}" || fail

    touch "${knownHosts}" || fail
    chmod 644 "${knownHosts}" || fail
  fi

  if ! ssh-keygen -F "${hostName}" >/dev/null; then
    ssh-keyscan -T 60 -H "${hostName}" >> "${knownHosts}" || fail
  fi
}
