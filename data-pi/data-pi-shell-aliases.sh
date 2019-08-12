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

alias data-pi='ssh -q -L 8385:localhost:8384 -L 19998:localhost:19999 ubuntu@stan-data-pi.local'
alias data-pi-onion='ssh -q -L 8385:localhost:8384 -L 19998:localhost:19999 -o ProxyCommand="nc -x localhost:9050 %h %p" ubuntu@3qxbzvlft57ftlsqgmsnag5nbm7cgopcyi4fufvlzyxdwlelxvodqmad.onion'

alias data-pi-unlock='export BW_SESSION="$(bw unlock --raw)" && bw get password "kelly disk key" | ssh ubuntu@stan-data-pi.local "echo unlocking... && ! { findmnt -M ~/kelly > /dev/null && echo already unlocked; } && sudo cryptsetup luksOpen /dev/sda1 kelly && sudo fsck -pf /dev/mapper/kelly && sudo mount /dev/mapper/kelly ~/kelly && sudo systemctl start syncthing-kelly@ubuntu.service && echo done"'
alias data-pi-onion-unlock='export BW_SESSION="$(bw unlock --raw)" && bw get password "kelly disk key" | ssh -o ProxyCommand="nc -x localhost:9050 %h %p" ubuntu@3qxbzvlft57ftlsqgmsnag5nbm7cgopcyi4fufvlzyxdwlelxvodqmad.onion "echo unlocking... && ! { findmnt -M ~/kelly > /dev/null && echo already unlocked; } && sudo cryptsetup luksOpen /dev/sda1 kelly && sudo fsck -pf /dev/mapper/kelly && sudo mount /dev/mapper/kelly ~/kelly && sudo systemctl start syncthing-kelly@ubuntu.service && echo done"'

alias data-pi-halt="ssh ubuntu@stan-data-pi.local 'echo halting... && sudo halt'"
alias data-pi-reboot="ssh ubuntu@stan-data-pi.local 'echo rebooting... && sudo reboot'"
