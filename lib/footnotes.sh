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

deploy-lib::footnotes::init() {
  DEPLOY_FOOTNOTES="$(mktemp)" || fail "Unable to create temp file"
  export DEPLOY_FOOTNOTES
}

deploy-lib::footnotes::add() {
  if [ -n "${DEPLOY_FOOTNOTES:-}" ] && [ -f "${DEPLOY_FOOTNOTES:-}" ]; then
    echo "$1" >> "${DEPLOY_FOOTNOTES}" || fail
  else
    fail "$1"
  fi
}

deploy-lib::footnotes::flush() {
  if [ -f "${DEPLOY_FOOTNOTES}" ]; then
    if [ -s "${DEPLOY_FOOTNOTES}" ]; then
      cat "${DEPLOY_FOOTNOTES}" || fail
    fi
    rm "${DEPLOY_FOOTNOTES}" || fail
  else
    fail "Unable to find footnotes"
  fi
}

deploy-lib::footnotes::display-elapsed-time() {
  echo "Elapsed time: $((SECONDS / 3600))h$(((SECONDS % 3600) / 60))m$((SECONDS % 60))s"
}


deploy-lib::footnotes::display() {
  deploy-lib::footnotes::flush || fail
  deploy-lib::footnotes::display-elapsed-time || fail
}
