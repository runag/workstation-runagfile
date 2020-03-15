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

macos::deploy-workstation() {
  # init footnotes
  deploy-lib::footnotes::init || fail

  # maxfiles limit
  macos::increase-maxfiles-limit || fail

  # basic packages
  macos::install-basic-packages || fail

  if [ "${DEPLOY_NON_DEVELOPER_WORKSTATION:-}" != "true" ]; then
    # developer packages
    macos::install-developer-packages || fail
    macos::shellrcd::homebrew-ruby || fail

    # shell aliases
    deploy-lib::shellrcd::install || fail
    deploy-lib::shellrcd::use-nano-editor || fail
    deploy-lib::shellrcd::my-computer-deploy-shell-alias || fail
    data-pi::install-shellrcd::shell-aliases || fail

    # SSH keys
    deploy-lib::ssh::install-keys || fail
    macos::ssh::add-use-keychain-to-ssh-config || fail
    macos::ssh::add-ssh-key-password-to-keychain || fail

    # git
    deploy-lib::git::configure || fail

    # vscode
    vscode::install-config || fail
    vscode::install-extensions || fail

    # sublime text
    sublime::install-config || fail
  fi

  # flush footnotes
  deploy-lib::footnotes::flush || fail

  # communicate to the user that we have reached the end of a script without major errors
  echo "macos::deploy-workstation completed"
}

macos::increase-maxfiles-limit() {
  # based on https://unix.stackexchange.com/questions/108174/how-to-persistently-control-maximum-system-resource-consumption-on-mac

  local dst="/Library/LaunchDaemons/limit.maxfiles.plist"

  if [ ! -f "${dst}" ]; then
    sudo cp macos/limit.maxfiles.plist "${dst}" || fail "Unable to copy to $dst ($?)"

    sudo chmod 0644 "${dst}" || fail "Unable to chmod ${dst} ($?)"

    sudo chown root:wheel "${dst}" || fail "Unable to chown ${dst} ($?)"

    deploy-lib::footnotes::add "increase-maxfiles-limit: Please reboot your computer" || fail
  fi
}

macos::install-homebrew() {
  if ! command -v brew >/dev/null; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null || fail "Unable to install homebrew"
  fi
}

macos::ssh::add-use-keychain-to-ssh-config() {
  local sshConfigFile="${HOME}/.ssh/config"

  if [ ! -f "${sshConfigFile}" ]; then
    touch "${sshConfigFile}" || fail
  fi

  if grep --quiet "^# Use keychain" "${sshConfigFile}"; then
    echo "Use keychain config already present"
  else
tee -a "${sshConfigFile}" <<SHELL || fail "Unable to append to the file: ${sshConfigFile}"

# Use keychain
Host *
  UseKeychain yes
  AddKeysToAgent yes
SHELL
  fi
}

macos::ssh::add-ssh-key-password-to-keychain() {
  local keyFile="${HOME}/.ssh/id_rsa"
  if ssh-add -L | grep --quiet --fixed-strings "${keyFile}"; then
    echo "${keyFile} is already in the keychain"
  else
    deploy-lib::bitwarden::unlock || fail
    bw get password "password for my current ssh private key" \
      | SSH_ASKPASS=bin/cat.sh DISPLAY=1 ssh-add -K "${keyFile}"
    test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to obtain and store ssh key password"
  fi
}

macos::install-basic-packages() {
  # install homebrew
  macos::install-homebrew || fail

  # update and upgrade homebrew
  brew update || fail
  brew upgrade || fail

  # fan and battery
  brew cask install macs-fan-control || fail
  brew cask install coconutbattery || fail

  # syncthing
  brew install syncthing || fail
  brew services start syncthing || fail

  # productivity tools
  brew cask install bitwarden || fail
  brew cask install discord || fail
  brew cask install libreoffice || fail
  brew cask install skype || fail
  brew cask install the-unarchiver || fail
  brew cask install grandperspective || fail

  # please install it from the app store, as direct sources may be blocked in some countries
  # brew cask install telegram || fail

  # chromium
  brew cask install chromium || fail

  # media tools
  brew cask install vlc || fail
  brew cask install obs || fail
}

macos::install-developer-packages() {
  # bitwarden-cli
  brew install bitwarden-cli || fail

  # basic tools
  brew install jq || fail
  brew install midnight-commander || fail
  brew install ranger || fail
  brew install ncdu || fail
  brew install htop || fail
  brew install p7zip || fail
  brew install sysbench || fail
  brew install hwloc || fail
  brew install tmux || fail

  # dev tools
  brew install awscli || fail
  brew install graphviz || fail
  brew install imagemagick || fail
  brew install ghostscript || fail
  brew install shellcheck || fail

  # servers
  brew install memcached || fail
  brew install redis || fail
  brew install postgresql || fail

  # tor
  brew install tor || fail
  brew services start tor || fail

  # ffmpeg
  brew install ffmpeg || fail

  # nodejs and jarn
  brew install node || fail
  brew install yarn || fail

  # meld
  brew cask install meld || fail

  # sublime merge
  brew cask install sublime-merge || fail

  # sublime text 
  brew cask install sublime-text || fail
  
  # vscode
  brew cask install visual-studio-code || fail

  # vscode
  brew cask install iterm2 || fail

  # linode-cli
  pip3 install linode-cli --upgrade || fail

  # direnv
  brew install direnv || fail
}

macos::shellrcd::homebrew-ruby() {
  local output="${HOME}/.shellrc.d/homebrew-ruby.sh"
  local gemsPath; gemsPath="$(brew info ruby | grep -F "ruby/gems" | sed -e 's/^[[:space:]]*//')" || fail "Unable to get gemsPath"

  tee "${output}" <<SHELL || fail "Unable to write file: ${output} ($?)"
    export PATH="${gemsPath}:/usr/local/opt/ruby/bin:$PATH"
    export LDFLAGS="-L/usr/local/opt/ruby/lib"
    export CPPFLAGS="-I/usr/local/opt/ruby/include"
SHELL
}
