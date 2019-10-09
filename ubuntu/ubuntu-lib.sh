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

ubuntu::ensure-this-is-ubuntu-workstation() {
  if [ "${DESKTOP_SESSION:-}" != "ubuntu" ] && [ "${DESKTOP_SESSION:-}" != "ubuntu-wayland" ] ; then
    echo "This has to be an ubuntu workstation" >&2
    exit 1
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
    echo "fs.inotify.max_user_watches and fs.inotify.max_user_instances are already set"
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

ubuntu::install-ssh-keys() {
  if [ ! -d "${HOME}/.ssh" ]; then
    mkdir --parents --mode=0700 "${HOME}/.ssh" || fail
  fi

  deploy-lib::bitwarden::write-notes-to-file-if-not-exists "my current ssh private key" "${HOME}/.ssh/id_rsa" "077"
  deploy-lib::bitwarden::write-notes-to-file-if-not-exists "my current ssh public key" "${HOME}/.ssh/id_rsa.pub" "077"

  # if ! ssh-add -L | grep --quiet "^${HOME}/\\.ssh/id_rsa$"; then
  #   deploy-lib::bitwarden::unlock || fail
  #   true | DISPLAY= SSH_ASKPASS="bin/get-my-current-ssh-key-password" ssh-add || fail "ssh-add failed"
  # fi
}

ubuntu::fix-nvidia-gpu-background-image-glitch() {
  sudo install --mode=0755 --owner=root --group=root -D -t /usr/lib/systemd/system-sleep ubuntu/background-fix.sh || fail "Unable to install ubuntu/background-fix.sh ($?)"
}

ubuntu::configure-desktop-apps() {
  # use dconf-editor to determine key/value pairs
  # why did I use dbus-launch? "dbus-launch gsettings set ..."

  # Terminal
  gsettings set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false || fail "Unable to set gsettings ($?)"

  local terminalProfile; terminalProfile="$(gsettings get org.gnome.Terminal.ProfilesList default)" || fail "Unable to determine terminalProfile ($?)"
  local profilePath="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${terminalProfile:1:-1}/"

  gsettings set "$profilePath" exit-action 'hold' || fail "Unable to set gsettings ($?)"
  gsettings set "$profilePath" login-shell true || fail "Unable to set gsettings ($?)"

  # Nautilus
  gsettings set org.gnome.nautilus.list-view default-zoom-level 'small' || fail "Unable to set gsettings ($?)"
  gsettings set org.gnome.nautilus.list-view use-tree-view true || fail "Unable to set gsettings ($?)"
  gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' || fail "Unable to set gsettings ($?)"
  gsettings set org.gnome.nautilus.preferences show-delete-permanently true || fail "Unable to set gsettings ($?)"
  gsettings set org.gnome.nautilus.preferences show-hidden-files true || fail "Unable to set gsettings ($?)"

  # Desktop
  gsettings set org.gnome.nautilus.desktop trash-icon-visible false || fail "Unable to set gsettings ($?)"
  gsettings set org.gnome.nautilus.desktop volumes-visible false || fail "Unable to set gsettings ($?)"

  # Disable screen lock
  gsettings set org.gnome.desktop.session idle-delay 0 || fail "Unable to set gsettings ($?)"
}

ubuntu::configure-git() {
  git config --global user.name "${GIT_USER_NAME}" || fail
  git config --global user.email "${GIT_USER_EMAIL}" || fail
}

ubuntu::perhaps-add-hgfs-automount() {
  # https://askubuntu.com/a/1051620
  if hostnamectl status | grep --quiet "Virtualization\\:.*vmware"; then
    if ! grep --quiet "fuse.vmhgfs-fuse" /etc/fstab; then
      echo ".host:/  /mnt/hgfs  fuse.vmhgfs-fuse  defaults,allow_other,uid=1000  0  0" | sudo tee --append /etc/fstab || fail "Unable to write to /etc/fstab ($?)"
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

ubuntu::remove-user-dirs() {
  tee "${HOME}/.config/user-dirs.dirs" <<SHELL || fail "Unable to write file: ${HOME}/.config/user-dirs.dirs ($?)"
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
SHELL

  tee "${HOME}/.config/user-dirs.conf" <<SHELL || fail "Unable to write file: ${HOME}/.config/user-dirs.conf ($?)"
enabled=false
SHELL

  # The script will continue on any errors in rm, so non-empty directories will be preserved.
  deploy-lib::remove-dir-if-empty "$HOME/Documents"
  deploy-lib::remove-dir-if-empty "$HOME/Music"
  deploy-lib::remove-dir-if-empty "$HOME/Pictures"
  deploy-lib::remove-dir-if-empty "$HOME/Public"
  deploy-lib::remove-dir-if-empty "$HOME/Templates"
  deploy-lib::remove-dir-if-empty "$HOME/Videos"

  if [ -f "$HOME/examples.desktop" ]; then
    rm "$HOME/examples.desktop" || fail
  fi

  xdg-user-dirs-update || fail "Unable to perform xdg-user-dirs-update"

  if ! grep --quiet "^Desktop$" "${HOME}/.hidden"; then
    echo "Desktop" >> "${HOME}/.hidden" || fail
  fi

  if ! grep --quiet "^snap$" "${HOME}/.hidden"; then
    echo "snap" >> "${HOME}/.hidden" || fail
  fi

  if ! grep --quiet "^VirtualBox VMs$" "${HOME}/.hidden"; then
    echo "VirtualBox VMs" >> "${HOME}/.hidden" || fail
  fi
}
