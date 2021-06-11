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

ubuntu-workstation::deploy() {
  # disable screen lock
  gsettings set org.gnome.desktop.session idle-delay 0 || fail

  # update and upgrade
  apt::lazy-update-and-dist-upgrade || fail

  # install tools to use by the rest of the script
  apt::install-tools || fail

  # install basic tools
  ubuntu-workstation::install-basic-tools || fail

  # devtools
  ubuntu-workstation::install-developer-tools || fail

  # install rbenv, configure ruby
  ruby::apt::install || fail
  ruby::install-and-load-rbenv || fail
  ruby::dangerously-append-nodocument-to-gemrc || fail

  # update ruby packages
  ruby::update-globally-installed-gems || fail

  # install nodejs
  nodejs::apt::install || fail
  nodejs::install-and-load-nodenv || fail

  # update nodejs packages
  nodejs::update-globally-installed-packages || fail

  # increase inotify limits
  linux::configure-inotify || fail

  # gnome-keyring and libsecret (for git and ssh)
  apt::install-gnome-keyring-and-libsecret || fail
  git::install-libsecret-credential-helper || fail

  # shellrcd
  shell::install-shellrc-directory-loader "${HOME}/.bashrc" || fail
  shell::install-sopka-path-shellrc || fail
  shell::install-nano-editor-shellrc || fail
  shell::install-direnv-loader-shellrc || fail

  # bitwarden cli
  bitwarden::install-bitwarden-login-shellrc || fail
  bitwarden::install-cli || fail

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

  # GNU Privacy Assistant
  apt::install gpa || fail

  # gparted
  apt::install gparted || fail

  # install rclone
  ubuntu-workstation::install-rclone || fail

  # whois
  apt::install whois || fail

  # install cifs-utils
  apt::install cifs-utils || fail

  # install restic
  apt::install restic || fail

  # open-vm-tools
  if vmware::is-inside-vm; then
    apt::install open-vm-tools open-vm-tools-desktop || fail
  fi

  # software for bare metal workstation
  if linux::is-bare-metal; then
    ubuntu-workstation::install-obs-studio || fail
    ubuntu-workstation::install-copyq || fail

    apt::install ddccontrol gddccontrol ddccontrol-db i2c-tools || fail

    sudo snap install telegram-desktop || fail
    sudo snap install skype --classic || fail
    sudo snap install discord || fail
  fi

  # configure desktop
  ubuntu-workstation::configure-desktop || fail

  # configure git
  git::configure-user || fail
  git config --global core.autocrlf input || fail

  # install sublime configuration
  sublime::install-config || fail

  # enable systemd user instance without the need for the user to login
  sudo loginctl enable-linger "${USER}" || fail

  # postgresql
  sudo systemctl --now enable postgresql || fail
  postgresql::create-superuser-for-local-account || fail

  # secrets
  if [ -t 0 ]; then
    # the following commands use bitwarden, that requires password entry
    # subshell for unlocked bitwarden
    (
      # secrets
      ubuntu-workstation::deploy-secrets || fail

      # mount host folder
      if vmware::is-inside-vm; then
        ubuntu-workstation::setup-my-folder-mount || fail
      fi
    ) || fail
  fi

  if vmware::is-inside-vm; then
    backup::vm-home-to-host::setup || fail
  fi

  # cleanup
  apt::autoremove || fail

  # set "deployed" flag
  touch "${HOME}/.sopka.workstation.deployed" || fail

  # display footnotes if running on interactive terminal
  tools::perhaps-display-deploy-footnotes || fail
}

ubuntu-workstation::deploy-secrets() {
  # install ssh key, configure ssh to use it
  # bitwarden-object: "my ssh private key", "my ssh public key"
  ssh::install-keys "my" || fail

  # bitwarden-object: "my password for ssh private key"
  ssh::add-key-password-to-gnome-keyring "my" || fail

  # git access token
  # bitwarden-object: "my github personal access token"
  git::add-credentials-to-gnome-keyring "my" || fail
  git::use-libsecret-credential-helper || fail

  # rubygems
  # bitwarden-object: "my rubygems credentials"
  bitwarden::write-notes-to-file-if-not-exists "my rubygems credentials" "${HOME}/.gem/credentials" || fail

  # install sublime license key
  sublime::install-license || fail
}

ubuntu-workstation::configure-desktop() {
  # install dconf-editor
  apt::install dconf-editor || fail

  # configure gnome desktop
  if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    ubuntu-workstation::configure-gnome || fail
  fi

  # configure firefox
  ubuntu-workstation::configure-firefox || fail
  firefox::enable-wayland || fail

  # install and configure imwheel
  apt::install imwheel || fail
  ubuntu-workstation::configure-imwhell || fail

  # install vitals gnome shell extension
  if ! vmware::is-inside-vm; then
    if [ -n "${DISPLAY:-}" ]; then
      ubuntu-workstation::install-vitals || fail
    fi
  fi

  # remove user dirs
  ubuntu-workstation::remove-user-dirs || fail

  # hide folders
  ubuntu-workstation::hide-folder "Desktop" "snap" "VirtualBox VMs" || fail

  # apply fixes for nvidia
  if nvidia::is-card-present; then
    nvidia::fix-screen-tearing || fail
    nvidia::fix-gpu-background-image-glitch || fail
  fi
}

# use dconf-editor to find key/value pairs
#
# Don't use dbus-launch here because it will introduce
# side-effect to git::add-credentials-to-gnome-keyring and ssh::add-key-password-to-gnome-keyring
#
ubuntu-workstation::configure-gnome() (
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
)

ubuntu-workstation::configure-firefox() {
  firefox::set-pref "mousewheel.default.delta_multiplier_x" 200 || fail
  firefox::set-pref "mousewheel.default.delta_multiplier_y" 200 || fail
}

ubuntu-workstation::remove-user-dirs() {
  local dirsFile="${HOME}/.config/user-dirs.dirs"

  if [ -f "${dirsFile}" ]; then
    local tmpFile; tmpFile="$(mktemp)" || fail

    if [ -d "$HOME/Desktop" ]; then
      echo 'XDG_DESKTOP_DIR="$HOME/Desktop"' >>"${tmpFile}" || fail
    fi

    if [ -d "$HOME/Downloads" ]; then
      echo 'XDG_DOWNLOADS_DIR="$HOME/Downloads"' >>"${tmpFile}" || fail
    fi

    mv "${tmpFile}" "${dirsFile}" || fail

    echo 'enabled=false' >"${HOME}/.config/user-dirs.conf" || fail

    dir::remove-if-empty \
      "$HOME/Documents" \
      "$HOME/Music" \
      "$HOME/Pictures" \
      "$HOME/Public" \
      "$HOME/Templates" \
      "$HOME/Videos" || fail

    if [ -f "$HOME/examples.desktop" ]; then
      rm "$HOME/examples.desktop" || fail
    fi

    xdg-user-dirs-update || fail
  fi
}

ubuntu-workstation::hide-folder() {
  local folder
  for folder in "$@"; do
    file::append-line-unless-present "${folder}" "${HOME}/.hidden" || fail
  done
}

ubuntu-workstation::setup-my-folder-mount() {
  local hostIpAddress; hostIpAddress="$(vmware::get-host-ip-address)" || fail

  # bitwarden-object: "my microsoft account"
  mount::cifs "//${hostIpAddress}/Users/${USER}/my" "my" "my microsoft account" || fail
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

ubuntu-workstation::install-vitals() {
  local extensionsDir="${HOME}/.local/share/gnome-shell/extensions"
  local extensionUuid="Vitals@CoreCoding.com"

  apt::install gnome-shell-extensions gir1.2-gtop-2.0 lm-sensors || fail

  mkdir -p "${extensionsDir}" || fail

  git::clone-or-pull "https://github.com/corecoding/Vitals" "${extensionsDir}/${extensionUuid}" || fail

  gnome-extensions enable "${extensionUuid}" || fail
}

ubuntu-workstation::install-obs-studio() {
  sudo add-apt-repository --yes ppa:obsproject/obs-studio || fail
  apt::update || fail
  apt::install obs-studio guvcview || fail
}

ubuntu-workstation::install-copyq() {
  sudo add-apt-repository --yes ppa:hluk/copyq || fail
  apt::update || fail
  apt::install copyq || fail
}

ubuntu-workstation::install-rclone() {
  if ! command -v rclone >/dev/null; then
    curl --fail --silent --show-error https://rclone.org/install.sh | sudo bash
    test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to install rclone"
  fi
}

ubuntu-workstation::install-basic-tools() {
  apt::install \
    htop \
    mc \
    ncdu \
    p7zip-full \
    tmux \
      || fail
}

ubuntu-workstation::install-developer-tools() {
  apt::install \
    apache2-utils \
    autoconf \
    awscli \
    bison \
    build-essential \
    cloud-guest-utils \
    ffmpeg \
    ghostscript \
    graphviz \
    imagemagick \
    inotify-tools \
    letsencrypt \
    libffi-dev \
    libgdbm-dev \
    libgs-dev \
    libncurses-dev \
    libpq-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libxslt-dev \
    libyaml-dev \
    memcached \
    nginx \
    postgresql \
    postgresql-contrib \
    python-is-python3 \
    python3 \
    python3-pip \
    python3-psycopg2 \
    redis-server \
    shellcheck \
    sqlite3 \
    zlib1g-dev \
    zsh \
      || fail
}
