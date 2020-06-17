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

__xVhMyefCbBnZFUQtwqCs() {
  if [ -n "${VERBOSE:-}" ]; then
    set -o xtrace
  fi

  set -o nounset

  fail() {
    echo "${BASH_SOURCE[1]}:${BASH_LINENO[0]}: in \`${FUNCNAME[1]}': Error: ${1:-"Abnormal termination"}" >&2
    exit "${2:-1}"
  }

  deploy-lib::git::make-repository-clone-available() {
    local repoUrl="$1"
    local localCloneDir; localCloneDir="${2:-$(basename "$repoUrl")}" || fail
    local branch="${3:-"master"}"

    if [ ! -d "${localCloneDir}" ]; then
      git clone "${repoUrl}" "${localCloneDir}" || fail "Unable to clone ${repoUrl} into ${localCloneDir}"
    else
      local existingRepoUrl; existingRepoUrl="$(cd "${localCloneDir}" && git config --get remote.origin.url)" || fail "Unable to get existingRepoUrl"

      if [ "${existingRepoUrl}" = "${repoUrl}" ]; then
        (cd "${localCloneDir}" && git pull) || fail "Unable to pull from ${repoUrl}"
      else
        if (cd "${localCloneDir}" 2>/dev/null && git diff-index --quiet HEAD --); then
          rm -rf "${localCloneDir}" || fail "Unable to delete repository ${localCloneDir}"
          git clone "${repoUrl}" "${localCloneDir}" || fail "Unable to clone ${repoUrl} into ${localCloneDir}"
        else
          fail "Local clone ${localCloneDir} is cloned from ${existingRepoUrl} and there are local changes. It is expected to be a clone of ${repoUrl}."
        fi
      fi
    fi

    if [ -n "${branch}" ]; then
      (cd "${localCloneDir}" && git checkout "${branch}") || fail "Unable to checkout ${branch}"
    fi
  }

  if [[ "$OSTYPE" =~ ^linux ]]; then
    if ! command -v git; then
      sudo apt update || fail
      sudo apt install -y git || fail
    fi
  fi

  # on macos that may start git install process
  git --version >/dev/null || fail

  local clonePath="${HOME}/.stan-computer-deploy"

  deploy-lib::git::make-repository-clone-available "https://github.com/senotrusov/stan-computer-deploy.git" "${clonePath}" || fail
  deploy-lib::git::make-repository-clone-available "https://github.com/senotrusov/stan-deploy-lib.git" "${clonePath}/stan-deploy-lib" || fail

  cd "${clonePath}" || fail

  bin/deploy || fail
}

# I'm wrapping the script in the function with the random name, to ensure that in case if download fails in the middle,
# then "curl | bash" will not run some funny things
__xVhMyefCbBnZFUQtwqCs || return $?
