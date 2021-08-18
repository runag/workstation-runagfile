#!/usr/bin/env bash

#  Copyright 2012-2021 Stanislav Senotrusov <stan@senotrusov.com>
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

ubuntu-workstation::deploy-full-workstation() {
  ubuntu-workstation::deploy-workstation-base || fail

  # subshell to deploy secrets
  (
    ubuntu-workstation::deploy-secrets || fail

    if vmware::is-inside-vm; then
      ubuntu-workstation::deploy-host-folders-access || fail
    fi

    ubuntu-workstation::deploy-tailscale || fail
    ubuntu-workstation::deploy-backup || fail
  ) || fail
}

ubuntu-workstation::deploy-workstation-base() {
  # disable screen lock
  gsettings set org.gnome.desktop.session idle-delay 0 || fail

  # perform cleanup
  apt::autoremove || fail

  # update and upgrade
  apt::lazy-update || fail
  if [ "${GITHUB_ACTIONS:-}" != "true" ]; then
    apt::dist-upgrade || fail
  fi

  # install tools to use by the rest of the script
  apt::install-tools || fail

  # shellrc
  ubuntu-workstation::install-shellrc || fail

  # install system software
  ubuntu-workstation::install-system-software || fail

  # configure system
  ubuntu-workstation::configure-system || fail

  # install terminal software
  ubuntu-workstation::install-terminal-software || fail

  # configure git
  ubuntu-workstation::configure-git || fail

  # install build tools
  ubuntu-workstation::install-build-tools || fail

  # install and configure servers
  ubuntu-workstation::install-servers || fail
  ubuntu-workstation::configure-servers || fail

  # programming languages
  ubuntu-workstation::install-and-update-nodejs || fail
  ubuntu-workstation::install-and-update-ruby || fail
  ubuntu-workstation::install-and-update-python || fail

  # install & configure desktop software
  ubuntu-workstation::install-desktop-software || fail
  ubuntu-workstation::configure-desktop-software || fail
}

ubuntu-workstation::deploy-secrets() {
  # install bitwarden cli
  bitwarden::install-cli-with-nodejs || fail

  # install gnome-keyring and libsecret
  ( unset BW_SESSION && apt::install-gnome-keyring-and-libsecret ) || fail

  # install ssh key, configure ssh to use it
  # bitwarden-object: "my ssh private key", "my ssh public key"
  # bitwarden-object: "my password for ssh private key"
  ssh::install-keys "my" || fail
  ssh::add-key-password-to-gnome-keyring "my" || fail

  # git access token
  # bitwarden-object: "my github.com personal access token"
  ( unset BW_SESSION && git::install-with-libsecret-credential-helper ) || fail
  git::add-credentials-to-gnome-keyring "my" "github.com" || fail

  # rubygems
  # bitwarden-object: "my rubygems credentials"
  bitwarden::write-notes-to-file-if-not-exists "my rubygems credentials" "${HOME}/.gem/credentials" || fail

  # install sublime license key
  sublime::install-license || fail

  # install gpg key
  local key="84C200370DF103F0ADF5028FF4D70B8640424BEA"
  keys::install-gpg-key "${key}" "/media/${USER}/KEYS-DAILY" "keys/gpg/${key:(-8)}/${key:(-8)}-secret-subkeys.asc" || fail
  git::configure-signingkey "38F6833D4C62D3AF8102789772080E033B1F76B5!" || fail
}

ubuntu-workstation::deploy-host-folders-access() {
  # install bitwarden cli
  bitwarden::install-cli-with-nodejs || fail

  # install cifs-utils
  ( unset BW_SESSION && apt::install cifs-utils ) || fail

  # mount host folder
  local hostIpAddress; hostIpAddress="$(unset BW_SESSION && vmware::get-host-ip-address)" || fail

  # bitwarden-object: "my microsoft account"
  mount::cifs "//${hostIpAddress}/my" "my" "my microsoft account" || fail
  mount::cifs "//${hostIpAddress}/ephemeral-data" "ephemeral-data" "my microsoft account" || fail
}

ubuntu-workstation::deploy-tailscale() {
  # install bitwarden cli
  bitwarden::install-cli-with-nodejs || fail

  if ! command -v tailscale >/dev/null || tailscale::is-logged-out || [ "${UPDATE_SECRETS:-}" = true ]; then
    # get tailscale key  
    # bitwarden-object: "my tailscale reusable key"
    bitwarden::unlock || fail
    local tailscaleKey
    tailscaleKey="$(NODENV_VERSION=system bw get password "my tailscale reusable key")" || fail

    (
      unset BW_SESSION

      # install tailscale
      if ! command -v tailscale >/dev/null; then
        tailscale::install || fail
        tailscale::install-issue-2541-workaround || fail
      fi

      # logout if UPDATE_SECRETS is set
      if ! tailscale::is-logged-out && [ "${UPDATE_SECRETS:-}" = true ]; then
        sudo tailscale logout || fail
      fi

      # configure tailscale
      sudo tailscale up --authkey "${tailscaleKey}" || fail

    ) || fail
  fi
}

ubuntu-workstation::deploy-backup() {
  # install bitwarden cli
  bitwarden::install-cli-with-nodejs || fail

  # install restic key
  local key="stan"
  keys::install-restic-key "${key}" "/media/${USER}/KEYS-DAILY" "keys/restic/${key}.txt.asc" || fail

  # backup::vm-home-to-host::setup || fail
}

ubuntu-workstation::deploy-vm-server() {
  # perform cleanup
  apt::autoremove || fail

  # perform apt update and upgrade
  apt::lazy-update || fail
  if [ "${GITHUB_ACTIONS:-}" != "true" ]; then
    apt::dist-upgrade || fail
  fi

  # install open-vm-tools
  if vmware::is-inside-vm; then
    apt::install open-vm-tools || fail
  fi

  # install and configure sshd
  ssh::disable-password-authentication || fail
  apt::install openssh-server || fail
  sudo systemctl --now enable ssh || fail
  sudo systemctl reload ssh || fail

  # import ssh key
  apt::install ssh-import-id || fail
  ssh-import-id gh:senotrusov || fail

  # install avahi daemon
  apt::install avahi-daemon || fail
}

ubuntu-workstation::install-shellrc() {
  shell::install-shellrc-directory-loader "${HOME}/.bashrc" || fail
  shell::install-sopka-path-shellrc || fail
  shell::install-nano-editor-shellrc || fail
  bitwarden::install-bitwarden-login-shellrc || fail
}

ubuntu-workstation::install-system-software() {
  # install open-vm-tools
  if vmware::is-inside-vm; then
    apt::install open-vm-tools || fail
  fi

  # install cloud guest utils
  apt::install cloud-guest-utils || fail

  # install inotify tools
  apt::install inotify-tools || fail

  # install cifs-utils
  apt::install cifs-utils || fail
}

ubuntu-workstation::install-terminal-software() {
  apt::install \
    apache2-utils \
    awscli \
    certbot \
    ffmpeg \
    git \
    gnupg \
    graphviz \
    htop \
    imagemagick \
    iperf3 \
    mc \
    ncdu \
    p7zip-full \
    restic \
    shellcheck \
    sqlite3 \
    ssh-import-id \
    tmux \
    whois \
    zsh \
      || fail

  rclone::install || fail
}

ubuntu-workstation::install-build-tools() {
  apt::install \
    build-essential \
    libsqlite3-dev \
    libssl-dev \
      || fail
}

ubuntu-workstation::install-servers() {
  apt::install memcached || fail
  apt::install postgresql postgresql-contrib libpq-dev || fail
  apt::install redis-server || fail
}

ubuntu-workstation::install-and-update-nodejs() {
    # install nodejs
  nodejs::apt::install || fail
  nodejs::install-and-load-nodenv || fail

  # update nodejs packages
  nodejs::update-globally-installed-packages || fail
}

ubuntu-workstation::install-and-update-ruby() {
  # install rbenv, configure ruby
  ruby::apt::install || fail
  ruby::install-and-load-rbenv || fail
  ruby::dangerously-append-nodocument-to-gemrc || fail

  # update ruby packages
  ruby::update-globally-installed-gems || fail
}

ubuntu-workstation::install-and-update-python() {
  apt::install \
    python-is-python3 \
    python3 \
    python3-pip \
    python3-psycopg2 \
      || fail
}

ubuntu-workstation::install-desktop-software() {
  # open-vm-tools-desktop
  if vmware::is-inside-vm; then
    apt::install open-vm-tools-desktop || fail
  fi

  # install dconf-editor
  apt::install dconf-editor || fail

  # vscode
  vscode::install-and-configure || fail

  # sublime text and sublime merge
  sublime::apt::install-merge-and-text || fail

  # meld
  apt::install meld || fail

  # chromium
  sudo snap install chromium || fail

  # bitwarden
  sudo snap install bitwarden || fail

  # gparted
  apt::install gparted || fail

  # GNU Privacy Assistant
  apt::install gpa || fail

  # imwheel
  if [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then
    apt::install imwheel || fail
  fi

  # software for bare metal workstation
  if linux::is-bare-metal; then
    # copyq
    ubuntu-workstation::install-copyq || fail

    # hardware monitoring
    apt::install ddccontrol gddccontrol ddccontrol-db i2c-tools || fail
    ubuntu-workstation::install-vitals || fail

    # skype
    sudo snap install skype --classic || fail

    # telegram desktop
    sudo snap install telegram-desktop || fail

    # discord
    sudo snap install discord || fail

    # OBS studio
    ubuntu-workstation::install-obs-studio || fail
  fi
}

ubuntu-workstation::install-vitals() {
  local extensionsDir="${HOME}/.local/share/gnome-shell/extensions"
  local extensionUuid="Vitals@CoreCoding.com"

  apt::install gnome-shell-extensions gir1.2-gtop-2.0 lm-sensors || fail

  mkdir -p "${extensionsDir}" || fail

  git::place-up-to-date-clone "https://github.com/corecoding/Vitals" "${extensionsDir}/${extensionUuid}" || fail

  gnome-extensions enable "${extensionUuid}" || fail
}

ubuntu-workstation::install-copyq() {
  sudo add-apt-repository --yes ppa:hluk/copyq || fail
  apt::update || fail
  apt::install copyq || fail
}

ubuntu-workstation::install-obs-studio() {
  sudo add-apt-repository --yes ppa:obsproject/obs-studio || fail
  apt::update || fail
  apt::install obs-studio guvcview || fail
}

ubuntu-workstation::configure-system() {
  # increase inotify limits
  linux::configure-inotify || fail

  # enable systemd user instance without the need for the user to login
  sudo loginctl enable-linger "${USER}" || fail
}

ubuntu-workstation::configure-git() {
  git::configure-user || fail
  git config --global core.autocrlf input || fail
}

ubuntu-workstation::configure-servers() {
  # postgresql
  sudo systemctl --now enable postgresql || fail
  postgresql::create-superuser-for-local-account || fail
}

ubuntu-workstation::configure-desktop-software() {
  if [ -n "${DISPLAY:-}" ]; then
    # configure firefox
    ubuntu-workstation::configure-firefox || fail
    firefox::enable-wayland || fail

    # install sublime configuration
    sublime::install-config || fail

    # configure imwheel
    if [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then
      ubuntu-workstation::configure-imwhell || fail
    fi

    # configure home folders
    ubuntu-workstation::configure-home-folders || fail

    # configure gnome desktop
    ubuntu-workstation::configure-gnome || fail

    # apply fixes for nvidia
    # TODO: Check if I really need those fixes nowadays
    # if ubuntu-workstation::is-nvidia-gpu-present; then
    #   ubuntu-workstation::fix-nvidia-gpu-glitches || fail
    # fi
  fi
}

ubuntu-workstation::configure-firefox() {
  firefox::set-pref "mousewheel.default.delta_multiplier_x" 200 || fail
  firefox::set-pref "mousewheel.default.delta_multiplier_y" 200 || fail
}

ubuntu-workstation::configure-imwhell() {
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

ubuntu-workstation::configure-home-folders() {
  local dirsFile="${HOME}/.config/user-dirs.dirs"

  if [ -f "${dirsFile}" ]; then
    local tmpFile; tmpFile="$(mktemp)" || fail

    if [ -d "${HOME}/Desktop" ]; then
      echo 'XDG_DESKTOP_DIR="${HOME}/Desktop"' >>"${tmpFile}" || fail
    fi

    if [ -d "${HOME}/Downloads" ]; then
      echo 'XDG_DOWNLOADS_DIR="${HOME}/Downloads"' >>"${tmpFile}" || fail
    fi

    mv "${tmpFile}" "${dirsFile}" || fail

    echo 'enabled=false' >"${HOME}/.config/user-dirs.conf" || fail

    dir::remove-if-empty \
      "${HOME}/Documents" \
      "${HOME}/Music" \
      "${HOME}/Pictures" \
      "${HOME}/Public" \
      "${HOME}/Templates" \
      "${HOME}/Videos" || fail

    if [ -f "${HOME}/examples.desktop" ]; then
      rm "${HOME}/examples.desktop" || fail
    fi

    xdg-user-dirs-update || fail
  fi

  file::append-line-unless-present "Desktop" "${HOME}/.hidden" || fail
  file::append-line-unless-present "snap" "${HOME}/.hidden" || fail
}

ubuntu-workstation::configure-gnome() {
  # use dconf-editor to find key/value pairs
  #
  # Do not use dbus-launch here because it will introduce
  # side-effect to git::add-credentials-to-gnome-keyring and ssh::add-key-password-to-gnome-keyring
  #
  (
    gnome-set() { gsettings set "org.gnome.$1" "${@:2}" || fail; }
    gnome-get() { gsettings get "org.gnome.$1" "${@:2}"; }

    # Terminal
    local profileId profilePath

    if profileId="$(gnome-get Terminal.ProfilesList default 2>/dev/null)"; then
      local profilePath="Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profileId:1:-1}/"
      
      gnome-set "${profilePath}" exit-action 'hold' || fail
      gnome-set "${profilePath}" login-shell true || fail
    fi

    gnome-set Terminal.Legacy.Settings menu-accelerator-enabled false || fail
    gnome-set Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ copy '<Primary>c'
    gnome-set Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ paste '<Primary>v'

    # Desktop
    gnome-set shell.extensions.desktop-icons show-trash false || fail
    gnome-set shell.extensions.desktop-icons show-home false || fail

    # Dash
    gnome-set shell.extensions.dash-to-dock dash-max-icon-size 32 || fail
    gnome-set shell.extensions.dash-to-dock dock-fixed false || fail
    gnome-set shell.extensions.dash-to-dock dock-position 'BOTTOM' || fail
    gnome-set shell.extensions.dash-to-dock hide-delay 0.10000000000000001 || fail
    gnome-set shell.extensions.dash-to-dock require-pressure-to-show false || fail
    gnome-set shell.extensions.dash-to-dock show-apps-at-top true || fail
    gnome-set shell.extensions.dash-to-dock show-delay 0.10000000000000001 || fail

    # Nautilus
    gnome-set nautilus.list-view default-zoom-level 'small' || fail
    gnome-set nautilus.list-view use-tree-view true || fail
    gnome-set nautilus.preferences default-folder-viewer 'list-view' || fail
    gnome-set nautilus.preferences show-delete-permanently true || fail
    gnome-set nautilus.preferences show-hidden-files true || fail

    # Automatic timezone
    gnome-set desktop.datetime automatic-timezone true || fail

    # Input sources
    # on mac host: ('xkb', 'ru+mac')
    gnome-set desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ru')]" || fail

    # Disable sound alerts
    gnome-set desktop.sound event-sounds false || fail

    # Enable fractional scaling
    # gnome-set mutter experimental-features "['scale-monitor-framebuffer', 'x11-randr-fractional-scaling']" || fail

    # 1600 DPI mouse
    gnome-set desktop.peripherals.mouse speed -0.75 || fail
  ) || fail
}

ubuntu-workstation::is-nvidia-gpu-present() {
  lspci | grep --quiet "VGA.*NVIDIA Corporation"
  local savedPipeStatus="${PIPESTATUS[*]}"

  if [ "${savedPipeStatus}" = "0 0" ]; then
    return 0
  elif [ "${savedPipeStatus}" = "0 1" ]; then
    return 1
  else
    fail "Error calling lspci"
  fi
}

ubuntu-workstation::fix-nvidia-gpu-glitches() {
  # fix screen tearing
  # based on https://www.reddit.com/r/linuxquestions/comments/8fb9oj/how_to_fix_screen_tearing_ubuntu_1804_nvidia_390/
  local modprobeFile="/etc/modprobe.d/zz-nvidia-modeset.conf"
  if [ ! -f "${modprobeFile}" ]; then
    echo "options nvidia_drm modeset=1" | sudo tee "${modprobeFile}"
    test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to write to ${modprobeFile}"
    sudo update-initramfs -u || fail
    echo "Please reboot to activate screen tearing fix" >&2
  fi

  # fix background image glitch
  file::sudo-write "/usr/lib/systemd/system-sleep/nvidia--fix-gpu-background-image-glitch.sh" 0755 <<'SHELL' || fail
#!/bin/bash
case $1/$2 in
  pre/*)
    ;;
  post/*)
    if [ -f /var/cache/background-fix-state ]; then
      rm /var/cache/background-fix-state
      su - stan bash -c "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/warty-final-ubuntu.png'"
    else
      touch /var/cache/background-fix-state
      su - stan bash -c "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/Disco_Dingo_Alt_Default_by_Abubakar_NK.png'"
    fi
    ;;
esac
SHELL
}

backup::vm-home-to-host() {
  backup::vm-home-to-host::load-configuration || fail
  "$@" || fail
}

backup::vm-home-to-host::load-configuration() {
  local machineUuid; machineUuid="$(vmware::get-machine-uuid)" || fail

  export BACKUP_NAME="vm-home-to-host"
  export RESTIC_REPOSITORY="${HOME}/my/storage/vm-home-backups/${machineUuid}"
  export RESTIC_PASSWORD="null"
}

backup::vm-home-to-host::setup() (
  file::sudo-write "/etc/sudoers.d/dmidecode" 0440 root <<SHELL || fail
${USER} ALL=NOPASSWD: /usr/sbin/dmidecode
SHELL

  backup::vm-home-to-host::load-configuration || fail

  # install systemd service
  declare -A serviceOptions
  serviceOptions[NoNewPrivileges]=false
  restic::systemd::init-service serviceOptions || fail

  # enable timer
  declare -A timerOptions
  timerOptions[OnCalendar]="*:00/30"
  timerOptions[RandomizedDelaySec]="300"
  restic::systemd::enable-timer timerOptions || fail
)

backup::vm-home-to-host::create() (
  backup::vm-home-to-host::load-configuration || fail

  # I should probably make a special user service to wait until the network is up and the directory is mounted
  findmnt --mountpoint "${HOME}/my" >/dev/null || fail

  if [ ! -d "${RESTIC_REPOSITORY}" ]; then
    restic::init || fail
  fi

  # The purpose of this is to have relative paths in backup
  cd "${HOME}" || fail

  local quietMaybe=""; test -t 1 || quietMaybe="--quiet"

  restic backup ${quietMaybe} --one-file-system . || fail

  tools::do-once-per-day backup::vm-home-to-host::forget-and-check || fail
)

backup::vm-home-to-host::forget-and-check() {
  backup::vm-home-to-host::load-configuration || fail

  restic::forget-and-prune || fail
  restic::check-and-read-data || fail
}

ubuntu-workstation::change-hostname() {
  local hostname
  echo "Please enter new hostname:"
  IFS="" read -r hostname || fail

  linux::dangerously-set-hostname "${hostname}" || fail
}
