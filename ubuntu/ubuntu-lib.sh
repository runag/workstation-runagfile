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

ubuntu::bare-metal() {
  # "hostnamectl status" could also be used to detect that we are running insde the vm
  if grep --quiet "^flags.*:.*hypervisor" /proc/cpuinfo; then
    return 1
  else
    return 0
  fi
}

ubuntu::detect-lean-workstation() {
  local memorySize; memorySize="$(grep MemTotal /proc/meminfo | awk '{print $2}'; test "${PIPESTATUS[*]}" = "0 0")" || fail "Unable to determine the size of the available memory"

  if [ "${memorySize}" -le 4194304 ]; then
    export LEAN_WORKSTATION=true
  fi
}

ubuntu::set-timezone() {
  local timezone="$1"
  sudo timedatectl set-timezone "$timezone" || fail "Unable to set timezone ($?)"
}

ubuntu::set-hostname() {
  local hostname="$1"
  local hostnameFile=/etc/hostname

  echo "$hostname" | sudo tee "$hostnameFile" || fail "Unable to write to $hostnameFile ($?)"

  sudo hostname --file "$hostnameFile" || fail "Unable to load hostname from $hostnameFile ($?)"
}

ubuntu::set-locale() {
  local locale="$1"

  sudo locale-gen "$locale" || fail "Unable to run locale-gen ($?)"
  sudo update-locale "LANG=$locale" "LANGUAGE=$locale" "LC_CTYPE=$locale" "LC_ALL=$locale" || fail "Unable to run update-locale ($?)"

  export LANG="$locale"
  export LANGUAGE="$locale"
  export LC_CTYPE="$locale"
  export LC_ALL="$locale"
}

ubuntu::set-inotify-max-user-watches() {
  local sysctl="/etc/sysctl.conf"

  if [ ! -r "$sysctl" ]; then
    echo "Unable to find file: $sysctl" >&2
    exit 1
  fi

  if grep --quiet "^fs.inotify.max_user_watches" "$sysctl" && grep --quiet "^fs.inotify.max_user_instances" "$sysctl"; then
    echo "fs.inotify.max_user_watches and fs.inotify.max_user_instances are already set" >&2
  else
    echo "fs.inotify.max_user_watches=1000000" | sudo tee --append "$sysctl" || fail "Unable to write to $sysctl ($?)"

    echo "fs.inotify.max_user_instances=2048" | sudo tee --append "$sysctl" || fail "Unable to write to $sysctl ($?)"

    sudo sysctl -p || fail "Unable to update sysctl config ($?)"
  fi
}

ubuntu::install-bashrcd() {
  if [ ! -d "${HOME}/.bashrc.d" ]; then
    mkdir --parents "${HOME}/.bashrc.d" || fail "Unable to create the directory: ${HOME}/.bashrc.d"
  fi

  if grep --quiet "^# bashrc.d loader" "${HOME}/.bashrc"; then
    echo "bashrc.d loader already present"
  else
tee --append "${HOME}/.bashrc" <<SHELL || fail "Unable to append to the file: ${HOME}/.bashrc"

# bashrc.d loader
if [ -d "\${HOME}/.bashrc.d" ]; then
  for file_bb21go6nkCN82Gk9XeY2 in "\${HOME}/.bashrc.d"/*.sh; do
    if [ -f "\${file_bb21go6nkCN82Gk9XeY2}" ]; then
      . "\${file_bb21go6nkCN82Gk9XeY2}" || { echo "Unable to load file \${file_bb21go6nkCN82Gk9XeY2} (\$?)"; }
    fi
  done
  unset file_bb21go6nkCN82Gk9XeY2
fi
SHELL
  fi
}

ubuntu::install-my-computer-deploy-shell-alias() {
  local output="${HOME}/.bashrc.d/my-computer-deploy-shell-alias.sh"
  tee "${output}" <<SHELL || fail "Unable to write file: ${output} ($?)"
    alias my-computer-deploy="${PWD}/bin/shell"
SHELL
}

ubuntu::use-nano-editor() {
  local output="${HOME}/.bashrc.d/use-nano-editor.sh"
  tee "${output}" <<SHELL || fail "Unable to write file: ${output} ($?)"
  export EDITOR="$(which nano)"
SHELL
}

ubuntu::fix-nvidia-gpu-background-image-glitch() {
  sudo install --mode=0755 --owner=root --group=root -D -t /usr/lib/systemd/system-sleep ubuntu/background-fix.sh || fail "Unable to install ubuntu/background-fix.sh ($?)"
}

ubuntu::configure-desktop-apps() {
  # use dconf-editor to determine key/value pairs
  # why did I use dbus-launch? "dbus-launch gsettings set ..."

  # Terminal
  if gsettings get org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled; then
    gsettings set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false || fail "Unable to set gsettings ($?)"
  fi

  if gsettings get org.gnome.Terminal.ProfilesList default; then
    local terminalProfile; terminalProfile="$(gsettings get org.gnome.Terminal.ProfilesList default)" || fail "Unable to determine terminalProfile ($?)"
    local profilePath="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${terminalProfile:1:-1}/"

    gsettings set "$profilePath" exit-action 'hold' || fail "Unable to set gsettings ($?)"
    gsettings set "$profilePath" login-shell true || fail "Unable to set gsettings ($?)"
  fi

  # Nautilus
  if gsettings list-keys org.gnome.nautilus; then
    gsettings set org.gnome.nautilus.list-view default-zoom-level 'small' || fail "Unable to set gsettings ($?)"
    gsettings set org.gnome.nautilus.list-view use-tree-view true || fail "Unable to set gsettings ($?)"
    gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' || fail "Unable to set gsettings ($?)"
    gsettings set org.gnome.nautilus.preferences show-delete-permanently true || fail "Unable to set gsettings ($?)"
    gsettings set org.gnome.nautilus.preferences show-hidden-files true || fail "Unable to set gsettings ($?)"

    # Desktop
    gsettings set org.gnome.nautilus.desktop trash-icon-visible false || fail "Unable to set gsettings ($?)"
    gsettings set org.gnome.nautilus.desktop volumes-visible false || fail "Unable to set gsettings ($?)"
  fi

  # Disable screen lock
  if gsettings get org.gnome.desktop.session idle-delay; then
    gsettings set org.gnome.desktop.session idle-delay 0 || fail "Unable to set gsettings ($?)"
  fi

  # Auto set time zone
  if gsettings get org.gnome.desktop.datetime automatic-timezone; then
    gsettings set org.gnome.desktop.datetime automatic-timezone true || fail "Unable to set gsettings ($?)"
  fi

  # Dash
  if gsettings get org.gnome.shell.extensions.dash-to-dock dash-max-icon-size; then
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 38 || fail "Unable to set gsettings ($?)"
  fi

  # Sound alerts
  if gsettings get org.gnome.desktop.sound event-sounds; then
    gsettings set org.gnome.desktop.sound event-sounds false || fail "Unable to set gsettings ($?)"
  fi
}

ubuntu::install-ssh-keys() {
  if [ ! -d "${HOME}/.ssh" ]; then
    mkdir --mode=0700 "${HOME}/.ssh" || fail
  fi

  deploy-lib::bitwarden::write-notes-to-file-if-not-exists "my current ssh private key" "${HOME}/.ssh/id_rsa" "077" || fail
  deploy-lib::bitwarden::write-notes-to-file-if-not-exists "my current ssh public key" "${HOME}/.ssh/id_rsa.pub" "077" || fail

  if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
    if ! secret-tool lookup unique "ssh-store:${HOME}/.ssh/id_rsa" >/dev/null; then
      deploy-lib::bitwarden::unlock || fail
      bw get password "my current password for ssh private key" \
        | secret-tool store --label="Unlock password for: ${HOME}/.ssh/id_rsa" unique "ssh-store:${HOME}/.ssh/id_rsa"
      test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to obtain and store ssh key password"
    fi
  fi
}

ubuntu::compile-git-credential-libsecret() {
  if [ ! -f /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret ]; then
    cd /usr/share/doc/git/contrib/credential/libsecret || fail
    sudo make || fail
  fi
}

ubuntu::configure-git() {
  git config --global user.name "${GIT_USER_NAME}" || fail
  git config --global user.email "${GIT_USER_EMAIL}" || fail

  if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
    if ! secret-tool lookup server github.com user "${GITHUB_LOGIN}" protocol https xdg:schema org.gnome.keyring.NetworkPassword >/dev/null; then
      deploy-lib::bitwarden::unlock || fail
      bw get password "my github personal access token" \
        | secret-tool store --label="Git: https://github.com/" server github.com user "${GITHUB_LOGIN}" protocol https xdg:schema org.gnome.keyring.NetworkPassword
      test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to obtain and store github personal access token"
    fi
  fi

  git config --global credential.helper /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret || fail
}

ubuntu::remove-user-dirs() {
  local dirsFile="${HOME}/.config/user-dirs.dirs"

  if [ -f "${dirsFile}" ]; then
    local tmpFile; tmpFile="$(mktemp)" || fail "Unable to create temp file"

    if [ -d "$HOME/Desktop" ]; then
      echo 'XDG_DESKTOP_DIR="$HOME/Desktop"' >>"${tmpFile}" || fail
    fi

    if [ -d "$HOME/Downloads" ]; then
      echo 'XDG_DESKTOP_DIR="$HOME/Downloads"' >>"${tmpFile}" || fail
    fi

    mv "${tmpFile}" "${dirsFile}" || fail

    echo 'enabled=false' >"${HOME}/.config/user-dirs.conf" || fail

    deploy-lib::remove-dir-if-empty "$HOME/Documents" || fail
    deploy-lib::remove-dir-if-empty "$HOME/Music" || fail
    deploy-lib::remove-dir-if-empty "$HOME/Pictures" || fail
    deploy-lib::remove-dir-if-empty "$HOME/Public" || fail
    deploy-lib::remove-dir-if-empty "$HOME/Templates" || fail
    deploy-lib::remove-dir-if-empty "$HOME/Videos" || fail

    if [ -f "$HOME/examples.desktop" ]; then
      rm "$HOME/examples.desktop" || fail
    fi

    xdg-user-dirs-update || fail "Unable to perform xdg-user-dirs-update"

    local hiddenFile="${HOME}/.hidden"

    if [ -d "$HOME/Desktop" ] && ! grep --quiet "^Desktop$" "${hiddenFile}"; then
      echo "Desktop" >>"${hiddenFile}" || fail
    fi

    if ! grep --quiet "^snap$" "${hiddenFile}"; then
      echo "snap" >>"${hiddenFile}" || fail
    fi

    if ! grep --quiet "^VirtualBox VMs$" "${hiddenFile}"; then
      echo "VirtualBox VMs" >>"${hiddenFile}" || fail
    fi
  fi
}

ubuntu::perhaps-add-hgfs-automount() {
  # https://askubuntu.com/a/1051620
  # TODO: Do I really need x-systemd.device-timeout here? think it works well even without it.
  if hostnamectl status | grep --quiet "Virtualization\\:.*vmware"; then
    if ! grep --quiet "fuse.vmhgfs-fuse" /etc/fstab; then
      echo ".host:/  /mnt/hgfs  fuse.vmhgfs-fuse  defaults,allow_other,uid=1000,nofail,x-systemd.device-timeout=3s  0  0" | sudo tee --append /etc/fstab || fail "Unable to write to /etc/fstab ($?)"
    fi
  fi
}

ubuntu::symlink-hgfs-mounts() {
  if findmnt -M /mnt/hgfs >/dev/null; then
    local f dirPath dirName
    for f in /mnt/hgfs/*; do echo "${f}"; done | while IFS="" read -r dirPath; do
      dirName="$(basename "$dirPath")" || fail
      if [ ! -e "${HOME}/${dirName}" ]; then
        ln --symbolic "${dirPath}" "${HOME}/${dirName}" || fail "unable to create symlink to ${dirPath}"
      fi
    done
  fi
}

ubuntu::setup-imwhell() {
  local outputFile="${HOME}/.imwheelrc"
  tee "${outputFile}" <<SHELL || fail "Unable to write file: ${outputFile} ($?)"
".*"
None,      Up,   Button4, 3
None,      Down, Button5, 3
Control_L, Up,   Control_L|Button4
Control_L, Down, Control_L|Button5
Shift_L,   Up,   Shift_L|Button4
Shift_L,   Down, Shift_L|Button5
SHELL

  if [ ! -d "${HOME}/.config/autostart" ]; then
    mkdir --parents "${HOME}/.config/autostart" || fail
  fi

  local outputFile="${HOME}/.config/autostart/imwheel.desktop"
  tee "${outputFile}" <<SHELL || fail "Unable to write file: ${outputFile} ($?)"
[Desktop Entry]
Type=Application
Exec=/usr/bin/imwheel
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=IMWheel
Name=IMWheel
Comment[en_US]=Custom scroll speed
Comment=Custom scroll speed
SHELL

  /usr/bin/imwheel --kill
}

# requires xcape, it is installed by apt::install-xfce-related-packages
ubuntu::setup-super-key-to-xfce-menu-workaround() {
  # Alternatives:
  #   https://github.com/hanschen/ksuperkey
  #   https://www.linux-apps.com/p/1081256/
  #   https://github.com/JixunMoe/xfce-superkey
  #
  if command -v xcape >/dev/null; then
    if [ ! -d "${HOME}/.config/autostart" ]; then
      mkdir --parents "${HOME}/.config/autostart" || fail
    fi

    local outputFile="${HOME}/.config/autostart/super-key-to-xfce-menu.desktop"
    tee "${outputFile}" <<SHELL || fail "Unable to write file: ${outputFile} ($?)"
[Desktop Entry]
Type=Application
Exec=/usr/bin/xcape -e 'Super_L=Control_L|Escape'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=super-key-to-xfce-menu
Name=super-key-to-xfce-menu
Comment[en_US]=Custom scroll speed
Comment=Custom scroll speed
SHELL

    if ! pgrep -cf "/usr/bin/xcape -e Super_L=Control_L|Escape" >/dev/null; then
      /usr/bin/xcape -e 'Super_L=Control_L|Escape' || fail
    fi
  fi
}
