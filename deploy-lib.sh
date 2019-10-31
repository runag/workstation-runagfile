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

fail() {
  echo "${BASH_SOURCE[1]}:${BASH_LINENO[0]}: in \`${FUNCNAME[1]}': Error: ${1:-"Abnormal termination"}" >&2
  exit "${2:-1}"
}

deploy-lib::sudo-write-file() {
  local dest="$1"
  local mode="${2:-0644}"
  local owner="${3:-root}"
  local group="${4:-$owner}"

  local dirName; dirName="$(dirname "${dest}")" || fail "Unable to get dirName of '${dest}' ($?)"

  sudo mkdir --parents "${dirName}" || fail "Unable to mkdir --parents '${dirName}' ($?)"

  cat | sudo tee "$dest"
  test "${PIPESTATUS[*]}" = "0 0" || fail "Unable to cat or write to '$dest'"

  sudo chmod "$mode" "$dest" || fail "Unable to chmod '${dest}' ($?)"
  sudo chown "$owner:$group" "$dest" || fail "Unable to chown '${dest}' ($?)"
}

deploy-lib::remove-dir-if-empty() {
  if [ -d "$1" ]; then
    # Note: no "|| fail" here because if directory is not empty rm will set the erorr status
    rm --dir "$1"
    true
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

  deploy-lib::add-host-to-ssh-known-hosts bitbucket.org || fail
  deploy-lib::add-host-to-ssh-known-hosts github.com || fail

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

deploy-lib::add-host-to-ssh-known-hosts() {
  local hostName="$1"
  local knownHosts="${HOME}/.ssh/known_hosts"

  if ! command -v ssh-keygen >/dev/null; then
    fail "ssh-keygen not found"
  fi

  if [ ! -f "${knownHosts}" ]; then
    local knownHostsDirname; knownHostsDirname="$(dirname "${knownHosts}")" || fail

    mkdir --parents "${knownHostsDirname}" || fail
    chmod 700 "${knownHostsDirname}" || fail

    touch "${knownHosts}" || fail
    chmod 644 "${knownHosts}" || fail
  fi

  if ! ssh-keygen -F "${hostName}" >/dev/null; then
    ssh-keyscan -T 60 -H "${hostName}" >> "${knownHosts}" || fail
  fi
}

deploy-lib::install-config() {
  src="$1"
  dst="$2"

  if [ -f "${dst}" ]; then
    if ! diff "${src}" "${dst}" >/dev/null 2>&1; then
      if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
        if command -v meld >/dev/null; then
          meld "${src}" "${dst}"
          local meldExitStatus=$?
          if [ "${meldExitStatus}" = 134 ] && [ -n "${SWAYSOCK:-}" ]; then
            if ! diff "${src}" "${dst}" >/dev/null 2>&1; then
              deploy-lib::footnotes::add "Unable to merge configs ${src} and ${dst}: merge was not complete" || fail
            fi
          elif [ "${meldExitStatus}" != 0 ]; then
            fail "Unable to merge configs ${src} and ${dst} ($?)"
          fi
        else
          fail "Unable to merge configs ${src} and ${dst}: meld not found"
        fi
      else
        deploy-lib::footnotes::add "Unable to merge configs ${src} and ${dst}: display not found" || fail
      fi
    fi
  else
    install --mode=0644 "${src}" -D "${dst}" || fail "Unable to install config from ${src} to ${dst} ($?)"
  fi
}

deploy-lib::merge-config() {
  src="$1"
  dst="$2"

  if [ -f "${dst}" ]; then
    if ! diff "${src}" "${dst}" >/dev/null 2>&1; then
      if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
        if command -v meld >/dev/null; then
          meld --newtab "${src}" "${dst}" &
        else
          fail "Unable to merge configs ${src} and ${dst}: meld not found"
        fi
      else
        deploy-lib::footnotes::add "Unable to merge configs ${src} and ${dst}: display not found" || fail
      fi
    fi
  fi
}

deploy-lib::bitwarden::unlock() {
  if [ -z "${BW_SESSION:-}" ]; then
    local errorString
    if ! errorString="$(bw sync --raw 2>&1)"; then
      if [ "${errorString}" = "You are not logged in." ]; then
        echo "Please enter your bitwarden password to login"
        if ! BW_SESSION="$(bw login "${BITWARDEN_LOGIN}" --raw)"; then
          fail "Unable to login to bitwarden"
        fi
        export BW_SESSION
      fi
    fi
  fi

  if [ -z "${BW_SESSION:-}" ]; then
    echo "Please enter your bitwarden to unlock the vault"

    if ! BW_SESSION="$(bw unlock --raw)"; then
      fail "Unable to unlock bitwarden database"
    fi

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
        mkdir --parents "${dirName}" || fail
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

deploy-lib::github::get-release-by-label() {
  local repoPath="$1"
  local label="$2"
  local release="${3:-latest}"

  local apiUrl="https://api.github.com/repos/${repoPath}/releases/${release}"
  local jqFilter=".assets[] | select(.label == \"${label}\").browser_download_url"
  local fileUrl; fileUrl="$(curl --fail --silent --show-error "${apiUrl}" | jq --raw-output --exit-status "${jqFilter}"; test "${PIPESTATUS[*]}" = "0 0")" || fail

  if [ -z "${fileUrl}" ]; then
    fail "Can't find release URL for ${repoPath} with label ${label} and release ${release}"
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
