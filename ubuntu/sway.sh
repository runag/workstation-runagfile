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

# This file implements instructions from
# https://github.com/swaywm/sway/wiki/Debian-10-(Buster)-Installation

sway::apt::install() {
  sudo apt-get install -o Acquire::ForceIPv4=true -y \
    build-essential cmake meson libwayland-dev wayland-protocols \
    libegl1-mesa-dev libgles2-mesa-dev libdrm-dev libgbm-dev libinput-dev \
    libxkbcommon-dev libudev-dev libpixman-1-dev libsystemd-dev libcap-dev \
    libxcb1-dev libxcb-composite0-dev libxcb-xfixes0-dev libxcb-xinput-dev \
    libxcb-image0-dev libxcb-render-util0-dev libx11-xcb-dev libxcb-icccm4-dev \
    freerdp2-dev libwinpr2-dev libpng-dev libavutil-dev libavcodec-dev \
    libavformat-dev universal-ctags \
    autoconf libtool \
    libpcre3-dev libcairo2-dev libpango1.0-dev libgdk-pixbuf2.0-dev xwayland \
    libcanberra0 libxcb-xkb1 \
      || fail "Unable to apt-get install ($?)"
}

sway::install-wlroots() (
  deploy-lib::git::cd-to-temp-clone "https://github.com/swaywm/wlroots" 0.7.0 || fail

  meson build || fail
  ninja -C build || fail
  sudo ninja -C build install || fail
  sudo ldconfig || fail

  deploy-lib::git::remove-temp-clone || fail
)

sway::install-jsonc() (
  deploy-lib::git::cd-to-temp-clone "https://github.com/json-c/json-c" json-c-0.13.1-20180305 || fail

  sh autogen.sh || fail
  ./configure --enable-threading --prefix=/usr/local || fail
  make || fail
  sudo make install || fail
  sudo ldconfig || fail

  deploy-lib::git::remove-temp-clone || fail
)

sway::install-scdoc() (
  deploy-lib::git::cd-to-temp-clone "https://git.sr.ht/~sircmpwn/scdoc" 1.9.7 || fail

  make PREFIX=/usr/local || fail
  sudo make PREFIX=/usr/local install || fail
  sudo ldconfig || fail

  deploy-lib::git::remove-temp-clone || fail
)

sway::install-sway() (
  deploy-lib::git::cd-to-temp-clone "https://github.com/swaywm/sway.git" 1.2 || fail

  meson build || fail
  ninja -C build || fail
  sudo ninja -C build install || fail

  deploy-lib::git::remove-temp-clone || fail
)

sway::install-swaybg() (
  deploy-lib::git::cd-to-temp-clone "https://github.com/swaywm/swaybg.git" 1.0 || fail

  meson build || fail
  ninja -C build || fail
  sudo ninja -C build install || fail

  deploy-lib::git::remove-temp-clone || fail
)

sway::install-kitty() {
  local kittyRelease; kittyRelease="$(deploy-lib::github::get-release-by-label "kovidgoyal/kitty" "Linux amd64 binary bundle")" || fail
  local installDir=/opt/kitty

  sudo mkdir --parents "${installDir}" || fail
  sudo tar --extract --xz --file="${kittyRelease}" --directory="${installDir}" || fail

  sudo ln --symbolic --force /opt/kitty/bin/kitty /usr/local/bin || fail
  sudo sed --in-place=.orig "s/urxvt/kitty/g" /usr/local/etc/sway/config || fail

  rm "${kittyRelease}" || fail
}

sway::install() {
  sway::apt::install || fail

  if [ ! -f /usr/local/lib/pkgconfig/wlroots.pc ] && [ ! -f /usr/local/lib/x86_64-linux-gnu/pkgconfig/wlroots.pc ]; then
    sway::install-wlroots || fail
  fi

  if [ ! -f /usr/local/lib/pkgconfig/json-c.pc ] && [ ! -f /usr/local/lib/x86_64-linux-gnu/pkgconfig/json-c.pc ]; then
    sway::install-jsonc || fail
  fi

  if [ ! -f /usr/local/lib/pkgconfig/scdoc.pc ] && [ ! -f /usr/local/lib/x86_64-linux-gnu/pkgconfig/scdoc.pc ]; then
    sway::install-scdoc || fail
  fi

  if [ ! -f /usr/local/bin/sway ]; then
    sway::install-sway || fail
  fi

  if [ ! -f /usr/local/bin/swaybg ]; then
    sway::install-swaybg || fail
  fi

  if [ ! -f /opt/kitty/bin/kitty ]; then
    sway::install-kitty || fail
  fi
}
