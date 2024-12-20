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
  Choco-Install nvidia-display-driver
}

# # Desktop: messengers
Choco-Install discord # proprietary

# # Desktop: browsers
# Choco-Install googlechrome --ignore-checksums # proprietary
Choco-Install chromium
Choco-Install firefox

# # Desktop: text editors
# Choco-Install meld
# Choco-Install sublimemerge # proprietary
# Choco-Install vscode # proprietary

# # Desktop: content creation and productivity
# Choco-Install libreoffice-still
Choco-Install avidemux
Choco-Install krita
Choco-Install streamlabs-obs

# # Desktop: content consumption
Choco-Install spotify --ignore-checksums # proprietary
Choco-Install vlc

# # Desktop: hardware
Choco-Install librehardwaremonitor

# # Build and developer tools
# Choco-Install git
# Choco-Install nodejs

# # Cloud and networking
# Choco-Install curl

# # Storage and files
# Choco-Install restic
# Choco-Install winscp
Choco-Install 7zip # partially under unRAR license, see details https://www.7-zip.org/
Choco-Install synctrayzor
Choco-Install windirstat

# # Benchmarks
# Choco-Install crystaldiskmark
