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

$ErrorActionPreference = "Stop"

# Use UTC for system clock
New-ItemProperty -Path 'HKLM:SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name RealTimeIsUniversal -Value 1 -PropertyType DWORD -Force

# Allow untrusted script execution
Write-Output "Setting execution policy..." 
Set-ExecutionPolicy Bypass -Scope Process -Force

# Install and configure chocolatey
if (-Not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
  Write-Output "Installing chocolatey..." 
  # Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://chocolatey.org/install.ps1"))
}

# Check if choco is installed
if (-Not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
  throw "Unable to find choco"
}

# Do not prompt for confirmation
choco feature enable -n allowGlobalConfirmation
if ($LASTEXITCODE -ne 0) { throw "Unable to set chocolatey feature" }

# Do not show download progress
if ("$env:CI" -eq "true") {
  choco feature disable -n showDownloadProgress
  if ($LASTEXITCODE -ne 0) { throw "Unable to set chocolatey feature" }
}

# Define helper function
function Choco-Install() {
  choco install $args
  if ($LASTEXITCODE -ne 0) { throw "Unable to install package" }
}

# Upgrade packages
if ("$env:CI" -ne "true") { # I don't need to update them in CI
  choco upgrade all --yes
  if ($LASTEXITCODE -ne 0) { throw "Unable to upgrade installed choco packages" }
}

# == Install packages ==

# Not in CI env
if ("$env:CI" -ne "true") {
  Choco-Install gpg4win # gpg4win hangs forever in CI
  Choco-Install nvidia-display-driver
}

# # Desktop: messengers
Choco-Install discord # proprietary

# # Desktop: browsers
Choco-Install chromium
Choco-Install firefox
Choco-Install googlechrome --ignore-checksums # proprietary

# # Desktop: text editors
Choco-Install meld
Choco-Install sublimemerge # proprietary
Choco-Install vscode # proprietary

# # Desktop: content creation and productivity
# Choco-Install inkscape
Choco-Install avidemux
Choco-Install krita
Choco-Install libreoffice-still
Choco-Install streamlabs-obs

# # Desktop: content consumption
Choco-Install spotify --ignore-checksums # proprietary
Choco-Install vlc

# # Desktop: hardware
Choco-Install librehardwaremonitor

# # Build and developer tools
Choco-Install git
Choco-Install golang
Choco-Install jq
Choco-Install msys2 # for ruby
Choco-Install nodejs
Choco-Install ruby

# # Cloud and networking
Choco-Install curl
Choco-Install tailscale # proprietary

# # Batch media processing
Choco-Install zbar

# # Storage and files
Choco-Install 7zip # partially under unRAR license, see details https://www.7-zip.org/
Choco-Install far
Choco-Install rclone
Choco-Install restic
Choco-Install smartmontools
Choco-Install synctrayzor
Choco-Install windirstat
Choco-Install winscp

# # Benchmarks
# Choco-Install crystaldiskmark
# Choco-Install iperf3

# Define git helper function
function Git-Clone-or-Pull($url, $dest){
  if (-not (Test-Path "C:\Program Files\Git\bin\git.exe")) {
    throw "Unable to find git"
  }

  if (Test-Path -Path "$dest") {
    & "C:\Program Files\Git\bin\git.exe" -C "$dest" pull
    if ($LASTEXITCODE -ne 0) { throw "Unable to git pull" }
  } else {
    & "C:\Program Files\Git\bin\git.exe" clone "$url" "$dest"
    if ($LASTEXITCODE -ne 0) { throw "Unable to git clone" }
  }
}

# Install runag shell scripts
# If you forked this, you may wish to change the following
$runag_repo = "runag/runag"
$runagfile_repo = "runag/workstation-runagfile"
$runagfile_dest = "workstation-runagfile-runag-github"

$runag_path = "$env:USERPROFILE\.runag"
$runagfile_path = "$runag_path\runagfiles\$runagfile_dest"

Git-Clone-or-Pull "https://github.com/$runag_repo.git" "$runag_path"
Git-Clone-or-Pull "https://github.com/$runagfile_repo.git" "$runagfile_path"

# Load chocolatey environment
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
Update-SessionEnvironment

# Use ridk tool from ruby installation to install MSYS2 and MINGW development toolchain for use in ruby's gems compilation
ridk install 2 3
if ($LASTEXITCODE -ne 0) { throw "Unable to install MSYS2 and MINGW development toolchain" }

# Install pass
ridk exec pacman --sync --needed --noconfirm pass
if ($LASTEXITCODE -ne 0) { throw "Unable to install pass" }
New-Item -ItemType SymbolicLink -Path "C:\Program Files\Git\usr\bin\pass" -Target "C:\tools\msys64\usr\bin\pass" -Force

# Enable ssh-agent
Set-Service -Name ssh-agent -StartupType Automatic
Set-Service -Name ssh-agent -Status Running
