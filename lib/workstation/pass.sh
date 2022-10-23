#!/usr/bin/env bash

#  Copyright 2012-2022 Stanislav Senotrusov <stan@senotrusov.com>
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

if declare -f sopka_menu::add >/dev/null; then
  sopka_menu::add_header "Workstation: pass" || fail

  sopka_menu::add workstation::pass::deploy || fail
  sopka_menu::add workstation::pass::import_offline_to_local || fail
  sopka_menu::add workstation::pass::sync_local_to_offline || fail
  sopka_menu::add workstation::pass::init || fail
fi

workstation::pass::deploy() {
  # install gpg keys
  workstation::install_gpg_keys || fail

  # import password store
  workstation::pass::import_offline_to_local || fail
}

workstation::pass::import_offline_to_local() {
  pass::import_git_store "${MY_PASSWORD_STORE_OFFLINE_PATH}" || fail
}

workstation::pass::sync_local_to_offline() {
  # [remote "local-workstation"]
  # 	url = ~/.password-store/.git
  # 	fetch = +refs/heads/*:refs/remotes/local-workstation/*
  # [branch "main"]
  #         remote = local-workstation
  #         merge = refs/heads/main
  #
  # git -C "${MY_PASSWORD_STORE_OFFLINE_PATH}" pull || fail

  # TODO: are they are truly equivalent? .git/FETCH_HEAD changes depends of what way I use

  git -C "${MY_PASSWORD_STORE_OFFLINE_PATH}" pull "${HOME}/.password-store" || fail
}

workstation::pass::init() {
  pass init "${MY_GPG_KEY}" || fail
}
