#!/usr/bin/env bash

#  Copyright 2012-2022 Rùnag project contributors
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


# shellcheck disable=SC2005
workstation::linux::generate_password() {

  # those are non-word characters on US ANSI keyboard:
  # `~!@#$%^&*()-_=+[{]}\|;:'",<.>/?
  #
  # a-zA-Z0-9 is 62 characters
  #
  # calculate in ruby:
  # 
  # Math.log2((62 + 7) ** 42) = 256 bits of entropy
  # Math.log2((62 + 23) ** 20) = 128 bits of entropy

  echo "42 symbols, 256 bits of entropy:"
  LC_ALL=C tr -dc 'a-zA-Z0-9!@#$\-=?' </dev/urandom | head -c 42 # 256

  printf "\n\n21 symbols, 128 bits of entropy:\n"
  LC_ALL=C tr -dc 'a-zA-Z0-9!@#$\-=?' </dev/urandom | head -c 21 # 128

  printf "\n\n22 symbols, 128 bits of entropy, no special characters:\n"
  LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 22 # 128

  printf "\n\n20 symbols, 128 bits of entropy (with more variety of non-word characters):\n"
  LC_ALL=C tr -dc 'a-zA-Z0-9!@#$%^&*()\-=[{]}\\:<.>/?' </dev/urandom | head -c 20 # 128

  printf "\n"
}
