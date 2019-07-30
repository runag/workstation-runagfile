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

normal() {
  for i in {1..5}
  do
    echo 1 > /sys/class/leds/led1/brightness
    sleep 3
    echo 0 > /sys/class/leds/led1/brightness
    sleep 0.5
  done
}

panic() {
  echo 1 > /sys/class/leds/led1/brightness
  sleep 0.35
  echo 0 > /sys/class/leds/led1/brightness
  sleep 0.15

  echo 1 > /sys/class/leds/led1/brightness
  sleep 0.35
  echo 0 > /sys/class/leds/led1/brightness
  sleep 0.15

  echo 1 > /sys/class/leds/led1/brightness
  sleep 0.35
  echo 0 > /sys/class/leds/led1/brightness
  sleep 0.15

  sleep 0.75
}

for (( ; ; ))
do
  if systemctl is-active --quiet syncthing-kelly@ubuntu.service && ! systemctl is-failed --quiet backup-data-pi.service && findmnt -M "/home/ubuntu/kelly" >/dev/null;  then
    normal
  else
    panic
  fi
done
