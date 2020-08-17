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
  if [ "${VERBOSE:-}" = true ]; then
    set -o xtrace
  fi

  set -o nounset

  fail() {
    echo "${BASH_SOURCE[1]}:${BASH_LINENO[0]}: in \`${FUNCNAME[1]}': Error: ${1:-"Abnormal termination"}" >&2
    exit "${2:-1}"
  }

  git::clone-or-pull() {
    local url="$1"
    local dest="$2"
    local branch="${3:-}"

    if [ -d "$dest" ]; then
      git -C "$dest" config remote.origin.url "${url}" || fail
      git -C "$dest" pull || fail
    else
      git clone "$url" "$dest" || fail
    fi

    if [ -n "${branch:-}" ]; then
      git -C "$dest" checkout "${branch}" || fail "Unable to checkout ${branch}"
    fi
  }

  if [[ "$OSTYPE" =~ ^linux ]]; then
    if ! command -v git >/dev/null; then
      if command -v apt >/dev/null; then
        sudo apt update || fail
        sudo apt install -y git || fail
      else
        fail "Unable to install git, apt not found"
      fi
    fi
  fi

  # on macos that will start git install process
  git --version >/dev/null || fail

  git::clone-or-pull "https://github.com/senotrusov/sopkafile.git" "${HOME}/.sopkafile" || fail
  git::clone-or-pull "https://github.com/senotrusov/sopka.git" "${HOME}/.sopka" || fail

  cd "${HOME}/.sopka" || fail

  bin/sopka "$@" || fail
}

# I'm wrapping the script in the function with the random name, to ensure that in case if download fails in the middle,
# then "curl | bash" hopefully will not run some funny things
__xVhMyefCbBnZFUQtwqCs "$@" || return $?
