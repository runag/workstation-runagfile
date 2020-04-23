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

deploy-lib::sudo-write-file() {
  local dest="$1"
  local mode="${2:-0644}"
  local owner="${3:-root}"
  local group="${4:-$owner}"

  local dirName; dirName="$(dirname "${dest}")" || fail "Unable to get dirName of '${dest}' ($?)"

  sudo mkdir -p "${dirName}" || fail "Unable to mkdir -p '${dirName}' ($?)"

  cat | sudo tee "$dest"
  test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to cat or write to '$dest'"

  sudo chmod "$mode" "$dest" || fail "Unable to chmod '${dest}' ($?)"
  sudo chown "$owner:$group" "$dest" || fail "Unable to chown '${dest}' ($?)"
}

deploy-lib::remove-dir-if-empty() {
  if [ -d "$1" ]; then
    # if directory is not empty then rm exit status will be non-zero
    rm --dir "$1" || true
  fi
}

deploy-lib::ssh::install-keys() {
  if [ ! -d "${HOME}/.ssh" ]; then
    mkdir -m 0700 "${HOME}/.ssh" || fail
  fi

  deploy-lib::bitwarden::write-notes-to-file-if-not-exists "my current ssh private key" "${HOME}/.ssh/id_rsa" "077" || fail
  deploy-lib::bitwarden::write-notes-to-file-if-not-exists "my current ssh public key" "${HOME}/.ssh/id_rsa.pub" "077" || fail
}

deploy-lib::ssh::add-host-known-hosts() {
  local hostName="$1"
  local knownHosts="${HOME}/.ssh/known_hosts"

  if ! command -v ssh-keygen >/dev/null; then
    fail "ssh-keygen not found"
  fi

  if [ ! -f "${knownHosts}" ]; then
    local knownHostsDirname; knownHostsDirname="$(dirname "${knownHosts}")" || fail

    mkdir -p "${knownHostsDirname}" || fail
    chmod 700 "${knownHostsDirname}" || fail

    touch "${knownHosts}" || fail
    chmod 644 "${knownHosts}" || fail
  fi

  if ! ssh-keygen -F "${hostName}" >/dev/null; then
    ssh-keyscan -T 60 -H "${hostName}" >> "${knownHosts}" || fail
  fi
}

deploy-lib::config::install() {
  src="$1"
  dst="$2"

  if [ -f "${dst}" ]; then
    deploy-lib::config::merge "${src}" "${dst}" || fail
  else
    local currentUserId; currentUserId="$(id -u)" || fail
    local currentGroupId; currentGroupId="$(id -g)" || fail

    local dirName; dirName="$(dirname "${dst}")" || fail "Unable to get dirName of '${dst}' ($?)"

    mkdir -p "${dirName}" || fail "Unable to mkdir -p '${dirName}' ($?)"

    cp "${src}" "${dst}" || fail "Unable to copy config from '${src}' to '${dst}' ($?)"

    chmod 0644 "$dst" || fail "Unable to chmod '${dst}' ($?)"
    
    chown "$currentUserId:$currentGroupId" "$dst" || fail "Unable to chown $USER:$USER '${dst}' ($?)"
  fi
}

deploy-lib::config::merge() {
  src="$1"
  dst="$2"

  if [ -f "${dst}" ]; then
    if ! diff "${src}" "${dst}" >/dev/null 2>&1; then

      if command -v git >/dev/null; then
        git diff --color --unified=6 --no-index "${dst}" "${src}" | tee
      else
        diff --context=6 --color "${dst}" "${src}"
      fi

      local action

      echo "Files are different:"
      echo "  ${src}"
      echo "  ${dst}"
      echo "Please choose an action to perform:"
      echo "  1: Use file from the deploy repository to replace file on this machine"
      echo "  2: Use file from this machine to save it to the deploy repository"
      echo "  3 (or Enter): Ignore conflict"

      IFS="" read -r action || fail

      if [ "${action}" = 1 ]; then
        cp "${src}" "${dst}" || fail
      elif [ "${action}" = 2 ]; then
        cp "${dst}" "${src}" || fail
      else
        deploy-lib::footnotes::add "Warning: File in the deploy repository ${src} is different from config file on this machine ${dst}" || fail
      fi
    fi
  fi
}

deploy-lib::bitwarden::unlock() {
  if [ -z "${BW_SESSION:-}" ]; then
    # the absence of error handling is intentional here
    local errorString="$(bw login "${BITWARDEN_LOGIN}" --raw 2>&1 </dev/null)"

    if [ "${errorString}" != "You are already logged in as ${BITWARDEN_LOGIN}." ]; then
      echo "Please enter your bitwarden password to login"

      BW_SESSION="$(bw login "${BITWARDEN_LOGIN}" --raw)" || fail "Unable to login to bitwarden"
      export BW_SESSION
    fi
  fi

  if [ -z "${BW_SESSION:-}" ]; then
    echo "Please enter your bitwarden password to unlock the vault"

    BW_SESSION="$(bw unlock --raw)" || fail "Unable to unlock bitwarden database"
    export BW_SESSION

    bw sync || fail "Unable to sync bitwarden"
  fi
}

deploy-lib::bitwarden::write-notes-to-file-if-not-exists() {
  local item="$1"
  local outputFile="$2"
  local setUmask="${3:-"0022"}"
  local bwdata
  
  if [ ! -f "${outputFile}" ]; then
    deploy-lib::bitwarden::unlock || fail
    
    if bwdata="$(bw get item "${item}")"; then
      local dirName; dirName="$(dirname "${outputFile}")" || fail
      
      if [ ! -d "${dirName}" ]; then
        mkdir -p "${dirName}" || fail
      fi

      echo "${bwdata}" | jq '.notes' --raw-output --exit-status | (umask "${setUmask}" && tee "${outputFile}.tmp")
      local savedPipeStatus="${PIPESTATUS[*]}"

      if [ "${savedPipeStatus}" = "0 0 0" ]; then
        if [ ! -s "${outputFile}.tmp" ]; then
          fail "Bitwarden item ${item} expected to have a non-empty note field"
        fi
        mv "${outputFile}.tmp" "${outputFile}" || fail "Unable to move temp file to the output file: ${outputFile}.tmp to ${outputFile}"
      else
        rm "${outputFile}.tmp" || fail "Unable to remove temp file: ${outputFile}.tmp"
        fail "Unable to produce '${outputFile}' (${savedPipeStatus}), Bitwarden item '${item}' may not present or have an empty note field"
      fi
    else
      echo "${bwdata}" >&2
      fail "Unable to bw get item ${item}"
    fi
  fi
}

deploy-lib::footnotes::init() {
  DEPLOY_FOOTNOTES="$(mktemp)" || fail "Unable to create temp file"
  export DEPLOY_FOOTNOTES
}

deploy-lib::footnotes::add() {
  if [ -n "${DEPLOY_FOOTNOTES:-}" ] && [ -f "${DEPLOY_FOOTNOTES:-}" ]; then
    echo "$1" >> "${DEPLOY_FOOTNOTES}" || fail
  else
    fail "$1"
  fi
}

deploy-lib::footnotes::flush() {
  if [ -f "${DEPLOY_FOOTNOTES}" ]; then
    if [ -s "${DEPLOY_FOOTNOTES}" ]; then
      cat "${DEPLOY_FOOTNOTES}" || fail
    fi
    rm "${DEPLOY_FOOTNOTES}" || fail
  else
    fail "Unable to find footnotes"
  fi
}

deploy-lib::git::cd-to-temp-clone() {
  local repoUrl="$1"
  local branch="${2:-}"

  local localCloneDir; localCloneDir="$(basename "$repoUrl")" || fail

  local tempDir; tempDir="$(mktemp --dry-run --tmpdir="${HOME}" "${localCloneDir}-XXXXXX")" || fail "Unable to create temp file"

  deploy-lib::git::make-repository-clone-available "${repoUrl}" "${tempDir}" "${branch}" || fail

  cd "${tempDir}" || fail

  export DEPLOY_LIB_GIT_TEMP_CLONE_DIR="${tempDir}" || fail
}

deploy-lib::git::remove-temp-clone() {
  rm -rf "${DEPLOY_LIB_GIT_TEMP_CLONE_DIR}" || fail
}

deploy-lib::git::make-repository-clone-available() {
  local repoUrl="$1"
  local localCloneDir; localCloneDir="${2:-$(basename "$repoUrl")}" || fail
  local branch="${3:-}"

  deploy-lib::ssh::add-host-known-hosts bitbucket.org || fail
  deploy-lib::ssh::add-host-known-hosts github.com || fail

  if [ ! -d "${localCloneDir}" ]; then
    git clone "${repoUrl}" "${localCloneDir}" || fail "Unable to clone ${repoUrl} into ${localCloneDir}"
  else
    local existingRepoUrl; existingRepoUrl="$(cd "${localCloneDir}" && git config --get remote.origin.url)" || fail "Unable to get existingRepoUrl"

    if [ "${existingRepoUrl}" != "${repoUrl}" ]; then
      rm -rf "${localCloneDir}" || fail "Unable to delete repository ${localCloneDir}"
      git clone "${repoUrl}" "${localCloneDir}" || fail "Unable to clone ${repoUrl} into ${localCloneDir}"
    else
      (cd "${localCloneDir}" && git pull) || fail "Unable to pull from ${repoUrl}"
    fi
  fi
  
  if [ -n "${branch}" ]; then
    (cd "${localCloneDir}" && git checkout "${branch}") || fail "Unable to pull from ${repoUrl}"
  fi
}

deploy-lib::git::configure() {
  git config --global user.name "${GIT_USER_NAME}" || fail
  git config --global user.email "${GIT_USER_EMAIL}" || fail
}

deploy-lib::github::get-release-by-label() {
  local repoPath="$1"
  local label="$2"
  local release="${3:-latest}"

  deploy-lib::github::get-release "${repoPath}" ".label == \"${label}\"" "${release}" || fail
}

deploy-lib::github::get-release-by-name() {
  local repoPath="$1"
  local label="$2"
  local release="${3:-latest}"

  deploy-lib::github::get-release "${repoPath}" ".name | test(\"${label}\")" "${release}" || fail
}

deploy-lib::github::get-release() {
  local repoPath="$1"
  local query="$2"
  local release="${3:-latest}"

  local apiUrl="https://api.github.com/repos/${repoPath}/releases/${release}"
  local jqFilter=".assets[] | select(${query}).browser_download_url"
  local fileUrl; fileUrl="$(curl --fail --silent --show-error "${apiUrl}" | jq --raw-output --exit-status "${jqFilter}"; test "${PIPESTATUS[*]}" = "0 0")" || fail

  if [ -z "${fileUrl}" ]; then
    fail "Can't find release URL for ${repoPath} that matched ${query} and release ${release}"
  fi

  local tempFile; tempFile="$(mktemp --tmpdir="${HOME}")" || fail "Unable to create temp file"

  curl \
    --location \
    --fail \
    --silent \
    --show-error \
    --output "$tempFile" \
    "$fileUrl" >/dev/null || fail "Unable to download ${fileUrl}"

  echo "${tempFile}"
}

deploy-lib::shellrcd::install() {
  if [ ! -d "${HOME}/.shellrc.d" ]; then
    mkdir -p "${HOME}/.shellrc.d" || fail "Unable to create the directory: ${HOME}/.shellrc.d"
  fi

  deploy-lib::shellrcd::add-loader "${HOME}/.bashrc" || fail
  deploy-lib::shellrcd::add-loader "${HOME}/.zshrc" || fail
}

deploy-lib::shellrcd::add-loader() {
  local shellrcFile="$1"

  if [ ! -f "${shellrcFile}" ]; then
    touch "${shellrcFile}" || fail
  fi

  if grep --quiet "^# shellrc.d loader" "${shellrcFile}"; then
    echo "shellrc.d loader already present"
  else
tee -a "${shellrcFile}" <<SHELL || fail "Unable to append to the file: ${shellrcFile}"

# shellrc.d loader
if [ -d "\${HOME}/.shellrc.d" ]; then
  for file_bb21go6nkCN82Gk9XeY2 in "\${HOME}/.shellrc.d"/*.sh; do
    if [ -f "\${file_bb21go6nkCN82Gk9XeY2}" ]; then
      . "\${file_bb21go6nkCN82Gk9XeY2}" || { echo "Unable to load file \${file_bb21go6nkCN82Gk9XeY2} (\$?)"; }
    fi
  done
  unset file_bb21go6nkCN82Gk9XeY2
fi
SHELL
  fi
}

deploy-lib::shellrcd::my-computer-deploy-path() {
  local output="${HOME}/.shellrc.d/my-computer-deploy-path.sh"
  tee "${output}" <<SHELL || fail "Unable to write file: ${output} ($?)"
    export PATH="${PWD}/bin:\$PATH"
SHELL
}

deploy-lib::shellrcd::use-nano-editor() {
  local output="${HOME}/.shellrc.d/use-nano-editor.sh"
  local nanoPath; nanoPath="$(command -v nano)" || fail
  tee "${output}" <<SHELL || fail "Unable to write file: ${output} ($?)"
  export EDITOR="${nanoPath}"
SHELL
}

deploy-lib::shellrcd::hook-direnv() {
  local output="${HOME}/.shellrc.d/hook-direnv.sh"
  tee "${output}" <<SHELL || fail "Unable to write file: ${output} ($?)"
  export DIRENV_LOG_FORMAT=""
  if [ "\$SHELL" = "/bin/zsh" ]; then
    eval "\$(direnv hook zsh)" || echo "Unable to hook direnv" >&2
  elif [ "\$SHELL" = "/bin/bash" ]; then
    eval "\$(direnv hook bash)" || echo "Unable to hook direnv" >&2
  fi
SHELL
}

deploy-lib::shellrcd::rbenv() {
  local output="${HOME}/.shellrc.d/rbenv.sh"
  local opensslDir

  if [[ "$OSTYPE" =~ ^darwin ]] && command -v brew >/dev/null; then
    opensslDir="$(brew --prefix openssl@1.1)" || fail
  fi

  tee "${output}" <<SHELL || fail "Unable to write file: ${output} ($?)"
    if [ -d "\$HOME/.rbenv/bin" ]; then
      if ! [[ ":\$PATH:" == *":\$HOME/.rbenv/bin:"* ]]; then
        export PATH="\$HOME/.rbenv/bin:\$PATH"
      fi
    fi
    if command -v rbenv >/dev/null; then
      if [ -z \${RBENV_INITIALIZED+x} ]; then
        eval "\$(rbenv init -)" || { echo "Unable to init rbenv" >&2; return 1; }
        if [ -n "${opensslDir}" ]; then
          export RUBY_CONFIGURE_OPTS="\${RUBY_CONFIGURE_OPTS:+"\${RUBY_CONFIGURE_OPTS} "}--with-openssl-dir=$(printf "%q" "${opensslDir}")"
        fi
        export RBENV_INITIALIZED=true
      fi
    fi
SHELL

  . "${output}" || fail
}

deploy-lib::shellrcd::nodenv() {
  local output="${HOME}/.shellrc.d/nodenv.sh"

  tee "${output}" <<SHELL || fail "Unable to write file: ${output} ($?)"
    if [ -d "\$HOME/.nodenv/bin" ]; then
      if ! [[ ":\$PATH:" == *":\$HOME/.nodenv/bin:"* ]]; then
        export PATH="\$HOME/.nodenv/bin:\$PATH"
      fi
    fi
    if command -v nodenv >/dev/null; then
      if [ -z \${NODENV_INITIALIZED+x} ]; then
        eval "\$(nodenv init -)" || { echo "Unable to init nodenv" >&2; return 1; }
        export NODENV_INITIALIZED=true
      fi
    fi
SHELL

  . "${output}" || fail
  nodenv rehash || fail
}

deploy-lib::ruby::install-gemrc() {
  local output="${HOME}/.gemrc"
  tee "${output}" <<SHELL || fail "Unable to write file: ${output} ($?)"
install: --no-document
update: --no-document
SHELL
}

deploy-lib::display-elapsed-time() {
  echo "Elapsed time: $((SECONDS / 3600))h$(((SECONDS % 3600) / 60))m$((SECONDS % 60))s"
}
