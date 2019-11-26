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

ubuntu::deploy-workstation() {
  deploy-lib::footnotes::init || fail

  sway::determine-conditional-install-flag || fail
  ubuntu::detect-lean-workstation || fail

  sudo --preserve-env="DESKTOP_SESSION,XDG_SESSION_TYPE,VERBOSE,DEPLOY_FOOTNOTES,DEPLOY_SWAY,DEPLOY_LEAN_WORKSTATION" bash -c "set -o nounset; $(declare -f); ubuntu::deploy-workstation::as-root" || fail "Unable to execute ubuntu::deploy-workstation::as-root ($?)"

  ubuntu::deploy-workstation::as-user || fail

  if [ -x /usr/lib/update-notifier/update-motd-reboot-required ]; then
    /usr/lib/update-notifier/update-motd-reboot-required >> "${DEPLOY_FOOTNOTES}" || fail
  fi

  deploy-lib::footnotes::flush || fail

  echo "ubuntu::deploy-workstation completed"
}

ubuntu::deploy-workstation::as-root() {
  if [ -n "${VERBOSE:-}" ]; then
    set -o xtrace
  fi

  # Install packages
  ubuntu::install-packages || fail

  # Set inotify-max-user-watches
  ubuntu::set-inotify-max-user-watches || fail

  # Compile git credential libsecret
  ubuntu::compile-git-credential-libsecret || fail

  # Enable syncthing
  if ubuntu::is-bare-metal; then
    sudo systemctl enable --now "syncthing@${SUDO_USER}.service" || fail
  fi

  # Add hgfs automount if needed
  ubuntu::perhaps-add-hgfs-automount || fail

  # Setup gnome keyring to load for text consoles
  ubuntu::setup-gnome-keyring-pam || fail

  # Fix screen tearing
  ubuntu::perhaps-fix-nvidia-screen-tearing || fail
}

ubuntu::deploy-workstation::as-user() {
  # Desktop configuration
  ubuntu::configure-desktop-apps || fail

  # Remove user dirs
  ubuntu::remove-user-dirs || fail

  # symlink hgfs mounts
  ubuntu::symlink-hgfs-mounts || fail

  # IMWhell for GNOME and XFCE
  if [ "${DESKTOP_SESSION:-}" = "ubuntu" ] || [ "${DESKTOP_SESSION:-}" = "ubuntu-wayland" ] || [ "${DESKTOP_SESSION:-}" = "xubuntu" ]; then
    ubuntu::setup-imwhell || fail
  fi

  # XFCE-specific
  if [ "${DESKTOP_SESSION:-}" = "xubuntu" ]; then
    ubuntu::setup-super-key-to-xfce-menu-workaround || fail
  fi

  # Shell aliases
  deploy-lib::install-shellrcd || fail
  deploy-lib::install-shellrcd::use-nano-editor || fail
  deploy-lib::install-shellrcd::my-computer-deploy-shell-alias || fail
  ubuntu::install-shellrcd::gnome-keyring-daemon-start || fail # SSH agent init for text console logins
  data-pi::install-shellrcd::shell-aliases || fail

  # Editors
  vscode::install-config || fail
  vscode::install-extensions || fail
  sublime::install-config || fail

  # SSH keys
  deploy-lib::install-ssh-keys || fail
  ubuntu::add-ssh-key-password-to-keyring || fail

  # Git
  deploy-lib::configure-git || fail
  ubuntu::add-git-credentials-to-keyring || fail

  # Gnome extensions
  ubuntu::install-corecoding-vitals-gnome-shell-extension || fail

  # Install sway
  if [ -n "${DEPLOY_SWAY:-}" ]; then
    sway::install || fail
    sway::install-config || fail
    sway::install-shellrcd || fail
  fi
}

ubuntu::is-bare-metal() {
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
    export DEPLOY_LEAN_WORKSTATION=true
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
    echo "fs.inotify.max_user_watches=1000000" | sudo tee -a "$sysctl" || fail "Unable to write to $sysctl ($?)"

    echo "fs.inotify.max_user_instances=2048" | sudo tee -a "$sysctl" || fail "Unable to write to $sysctl ($?)"

    sudo sysctl -p || fail "Unable to update sysctl config ($?)"
  fi
}

ubuntu::fix-nvidia-gpu-background-image-glitch() {
  sudo install --mode=0755 --owner=root --group=root -D -t /usr/lib/systemd/system-sleep ubuntu/background-fix.sh || fail "Unable to install ubuntu/background-fix.sh ($?)"
}

ubuntu::perhaps-fix-nvidia-screen-tearing() {
  # based on https://www.reddit.com/r/linuxquestions/comments/8fb9oj/how_to_fix_screen_tearing_ubuntu_1804_nvidia_390/
  local modprobeFile="/etc/modprobe.d/zz-nvidia-modeset.conf"
  if lspci | grep --quiet "VGA.*NVIDIA Corporation"; then
    if [ ! -f "${modprobeFile}" ]; then
      echo "options nvidia_drm modeset=1" | sudo tee "${modprobeFile}"
      sudo update-initramfs -u
      deploy-lib::footnotes::add "Please reboot to activate screen tearing fix (ubuntu::perhaps-fix-nvidia-screen-tearing)" || fail
    fi
  fi
}

ubuntu::configure-desktop-apps() {
  # use dconf-editor to find key/value pairs
  # I don't use dbus-launch here because it will introduce side-effect for ubuntu::add-git-credentials-to-keyring and ubuntu::add-ssh-key-password-to-keyring

  if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
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
    fi

    # Desktop 18.04
    if gsettings list-keys org.gnome.nautilus.desktop; then
      gsettings set org.gnome.nautilus.desktop trash-icon-visible false || fail "Unable to set gsettings ($?)"
      gsettings set org.gnome.nautilus.desktop volumes-visible false || fail "Unable to set gsettings ($?)"
    fi

    # Desktop 19.10
    if gsettings list-keys org.gnome.shell.extensions.desktop-icons; then
      gsettings set org.gnome.shell.extensions.desktop-icons show-trash false || fail "Unable to set gsettings ($?)"
      gsettings set org.gnome.shell.extensions.desktop-icons show-home false || fail "Unable to set gsettings ($?)"
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

    # Mouse
    # 2000 DPI
    if gsettings get org.gnome.desktop.peripherals.mouse speed; then
      gsettings set org.gnome.desktop.peripherals.mouse speed -0.950 || fail "Unable to set gsettings ($?)"
    fi

    # Input sources
    if gsettings get org.gnome.desktop.input-sources sources; then
      gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ru+mac')]" || fail "Unable to set gsettings ($?)"
    fi
  fi
}

ubuntu::add-ssh-key-password-to-keyring() {
  # There is an indirection here. I assume that if there is a DBUS_SESSION_BUS_ADDRESS available then 
  # the login keyring is also available and already initialized properly
  # I don't know yet how to check for login keyring specifically 
  if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    if ! secret-tool lookup unique "ssh-store:${HOME}/.ssh/id_rsa" >/dev/null; then
      deploy-lib::bitwarden::unlock || fail
      bw get password "my current password for ssh private key" \
        | secret-tool store --label="Unlock password for: ${HOME}/.ssh/id_rsa" unique "ssh-store:${HOME}/.ssh/id_rsa"
      test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to obtain and store ssh key password"
    fi
  else
    deploy-lib::footnotes::add "Unable to store ssh key password into the gnome keyring, DBUS not found" || fail
  fi
}

ubuntu::compile-git-credential-libsecret() (
  if [ ! -f /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret ]; then
    cd /usr/share/doc/git/contrib/credential/libsecret || fail
    sudo make || fail "Unable to compile libsecret"
  fi
)

ubuntu::add-git-credentials-to-keyring() {
  # There is an indirection here. I assume that if there is a DBUS_SESSION_BUS_ADDRESS available then 
  # the login keyring is also available and already initialized properly
  # I don't know yet how to check for login keyring specifically 
  if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    if ! secret-tool lookup server github.com user "${GITHUB_LOGIN}" protocol https xdg:schema org.gnome.keyring.NetworkPassword >/dev/null; then
      deploy-lib::bitwarden::unlock || fail
      bw get password "my github personal access token" \
        | secret-tool store --label="Git: https://github.com/" server github.com user "${GITHUB_LOGIN}" protocol https xdg:schema org.gnome.keyring.NetworkPassword
      test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to obtain and store github personal access token"
    fi
  else
    deploy-lib::footnotes::add "Unable to store git credentials into the gnome keyring, DBUS not found" || fail
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
      echo 'XDG_DOWNLOADS_DIR="$HOME/Downloads"' >>"${tmpFile}" || fail
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
      echo ".host:/  /mnt/hgfs  fuse.vmhgfs-fuse  defaults,allow_other,uid=1000,nofail,x-systemd.device-timeout=3s  0  0" | sudo tee -a /etc/fstab || fail "Unable to write to /etc/fstab ($?)"
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
  local repetitions="2"
  local outputFile="${HOME}/.imwheelrc"
  tee "${outputFile}" <<SHELL || fail "Unable to write file: ${outputFile} ($?)"
".*"
None,      Up,   Button4, ${repetitions}
None,      Down, Button5, ${repetitions}
Control_L, Up,   Control_L|Button4
Control_L, Down, Control_L|Button5
Shift_L,   Up,   Shift_L|Button4
Shift_L,   Down, Shift_L|Button5
SHELL

  if [ ! -d "${HOME}/.config/autostart" ]; then
    mkdir -p "${HOME}/.config/autostart" || fail
  fi

  local outputFile="${HOME}/.config/autostart/imwheel.desktop"
  tee "${outputFile}" <<SHELL || fail "Unable to write file: ${outputFile} ($?)"
[Desktop Entry]
Type=Application
Exec=/usr/bin/imwheel
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
OnlyShowIn=GNOME;XFCE;
Name[en_US]=IMWheel
Name=IMWheel
Comment[en_US]=Custom scroll speed
Comment=Custom scroll speed
SHELL

  /usr/bin/imwheel --kill
}

# requires xcape
ubuntu::setup-super-key-to-xfce-menu-workaround() {
  # Alternatives:
  #   https://github.com/hanschen/ksuperkey
  #   https://www.linux-apps.com/p/1081256/
  #   https://github.com/JixunMoe/xfce-superkey
  #
  if [ ! -d "${HOME}/.config/autostart" ]; then
    mkdir -p "${HOME}/.config/autostart" || fail
  fi

  local outputFile="${HOME}/.config/autostart/super-key-to-xfce-menu.desktop"
  tee "${outputFile}" <<SHELL || fail "Unable to write file: ${outputFile} ($?)"
[Desktop Entry]
Type=Application
Exec=/usr/bin/xcape -e 'Super_L=Control_L|Escape'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
OnlyShowIn=XFCE;
Name[en_US]=super-key-to-xfce-menu
Name=super-key-to-xfce-menu
Comment[en_US]=Custom scroll speed
Comment=Custom scroll speed
SHELL

  if ! pgrep -cf "/usr/bin/xcape -e Super_L=Control_L|Escape" >/dev/null; then
    /usr/bin/xcape -e 'Super_L=Control_L|Escape' || fail
  fi
}

# https://wiki.archlinux.org/index.php/GNOME/Keyring
# https://wiki.gnome.org/Projects/GnomeKeyring
# https://wiki.gnome.org/Projects/GnomeKeyring/Pam

ubuntu::setup-gnome-keyring-pam() {
  local pamFile="/etc/pam.d/login"
  if ! grep --quiet "pam_gnome_keyring" "${pamFile}"; then
    local tmpFile; tmpFile="$(mktemp)" || fail "Unable to create temp file"
    cat "${pamFile}" | ruby ubuntu/patch-pam-d-login.rb > "${tmpFile}"
    test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to patch ${pamFile}"
    sudo install --mode=0644 --owner=root --group=root "$tmpFile" -D "${pamFile}" || fail "Unable to install file: ${pamFile} ($?)"
    rm "${tmpFile}" || fail
  fi

  if ! grep --quiet "pam_gnome_keyring" /etc/pam.d/passwd && ! grep --quiet "pam_gnome_keyring" /etc/pam.d/common-password; then
    fail "pam_gnome_keyring is expected to be in /etc/pam.d/passwd or /etc/pam.d/common-password"
  fi
}

ubuntu::install-shellrcd::gnome-keyring-daemon-start() {
  local outputFile="${HOME}/.shellrc.d/gnome-keyring-daemon-start.sh"
  tee "${outputFile}" <<'SHELL' || fail "Unable to write file: ${outputFile} ($?)"
    if [ "${XDG_SESSION_TYPE}" = tty ] && [ -n "${GNOME_KEYRING_CONTROL:-}" ] && [ -z "${SSH_AUTH_SOCK:-}" ]; then
      eval "$(gnome-keyring-daemon --start)"
      export GNOME_KEYRING_CONTROL
      export SSH_AUTH_SOCK
    fi
SHELL
}
