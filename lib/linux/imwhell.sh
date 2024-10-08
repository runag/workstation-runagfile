#!/usr/bin/env bash

#  Copyright 2012-2024 Rùnag project contributors
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

workstation::linux::imwheel::deploy() {
  workstation::linux::imwheel::configure || fail
  workstation::linux::imwheel::reenable || fail
}

workstation::linux::imwheel::configure() {
  file::write --mode 0600 "${HOME}/.imwheelrc" <<EOF || fail

# In the absence of the following tedious list of modifiers,
# (alt/ctrl/shift/meta + scroll) does not work

"^(Sublime_merge|Sublime_text)$"
None,      Up,   Button4, 2
None,      Down, Button5, 2
Control_L, Up,   Control_L|Button4
Control_L, Down, Control_L|Button5
Control_R, Up,   Control_R|Button4
Control_R, Down, Control_R|Button5
Alt_L,     Up,   Button4, 4
Alt_L,     Down, Button5, 4
Alt_R,     Up,   Button4, 4
Alt_R,     Down, Button5, 4
Shift_L,   Up,   Shift_L|Button4
Shift_L,   Down, Shift_L|Button5
Shift_R,   Up,   Shift_R|Button4
Shift_R,   Down, Shift_R|Button5
Meta_L,    Up,   Meta_L|Button4
Meta_L,    Down, Meta_L|Button5
Meta_R,    Up,   Meta_R|Button4
Meta_R,    Down, Meta_R|Button5

# Without that wildcard match that seems just like a passthrough,
# well, it's not passing through without that

".*"
None,      Up,   Button4
None,      Down, Button5
Control_L, Up,   Control_L|Button4
Control_L, Down, Control_L|Button5
Control_R, Up,   Control_R|Button4
Control_R, Down, Control_R|Button5
Alt_L,     Up,   Alt_L|Button4
Alt_L,     Down, Alt_L|Button5
Alt_R,     Up,   Alt_R|Button4
Alt_R,     Down, Alt_R|Button5
Shift_L,   Up,   Shift_L|Button4
Shift_L,   Down, Shift_L|Button5
Shift_R,   Up,   Shift_R|Button4
Shift_R,   Down, Shift_R|Button5
Meta_L,    Up,   Meta_L|Button4
Meta_L,    Down, Meta_L|Button5
Meta_R,    Up,   Meta_R|Button4
Meta_R,    Down, Meta_R|Button5
EOF
}

workstation::linux::imwheel::reenable() {
  dir::should_exists --mode 0700 "${HOME}/.config" || fail
  dir::should_exists --mode 0700 "${HOME}/.config/autostart" || fail

  file::write --mode 0600 "${HOME}/.config/autostart/imwheel.desktop" <<EOF || fail
[Desktop Entry]
Type=Application
Exec=/usr/bin/bash -c 'if [ "\${XDG_SESSION_TYPE:-}" = "x11" ] || [ "\$(systemd-detect-virt)" = "vmware" ]; then /usr/bin/imwheel; fi'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
OnlyShowIn=GNOME;XFCE;
Name[en_US]=IMWheel
Name=IMWheel
Comment[en_US]=Scripting for mouse wheel and buttons
Comment=Scripting for mouse wheel and buttons
EOF

  if [ "${XDG_SESSION_TYPE:-}" = "x11" ] || [ "$(systemd-detect-virt)" = "vmware" ]; then
    /usr/bin/imwheel --kill || fail
  fi
}

workstation::linux::imwheel::disable() {
  rm "${HOME}/.config/autostart/imwheel.desktop" || fail
  pkill --full "/usr/bin/imwheel"
  [[ $? =~ ^[01]$ ]] || fail
}

workstation::linux::imwheel::debug() {
  /usr/bin/imwheel --kill --detach --debug || fail
}
