#  Copyright 2012-2022 Stanislav Senotrusov <stan@senotrusov.com>
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


# Ask a question
if ("$env:CI" -eq "true") {
  $install_developer_tools = 0
} else {
  $polar_question = "&Yes", "&No"
  $install_developer_tools = $Host.UI.PromptForChoice("Would you like to install developer tools?", "", $polar_question, 0)
}


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

if (-Not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
  throw "Unable to find choco"
}

choco feature enable -n allowGlobalConfirmation
if ($LASTEXITCODE -ne 0) { throw "Unable to set chocolatey feature" }

if ("$env:CI" -eq "true") {
  choco feature disable -n showDownloadProgress
  if ($LASTEXITCODE -ne 0) { throw "Unable to set chocolatey feature" }
}


# Install git
if (-not (Test-Path "C:\Program Files\Git\bin\git.exe")) {
  choco install git --yes
  if ($LASTEXITCODE -ne 0) { throw "Unable to install git" }
}

if (-not (Test-Path "C:\Program Files\Git\bin\git.exe")) {
  throw "Unable to find git"
}


# Clone repositories
function Git-Clone-or-Pull($url, $dest){
  if (Test-Path -Path "$dest") {
    & "C:\Program Files\Git\bin\git.exe" -C "$dest" pull
    if ($LASTEXITCODE -ne 0) { throw "Unable to git pull" }
  } else {
    & "C:\Program Files\Git\bin\git.exe" clone "$url" "$dest"
    if ($LASTEXITCODE -ne 0) { throw "Unable to git pull" }
  }
}

Git-Clone-or-Pull "https://github.com/senotrusov/sopka.git" "$env:USERPROFILE\.sopka"
Git-Clone-or-Pull "https://github.com/senotrusov/sopkafile.git" "$env:USERPROFILE\.sopkafile"


# Install choco packages
if ("$env:CI" -eq "true") {
  # gpg4win hangs forever in CI
  ( Get-Content "$env:USERPROFILE\.sopkafile\lib\choco\bare-metal-desktop.config" |
    Select-String -Pattern '"gpg4win"' -NotMatch ) |
  Set-Content "$env:USERPROFILE\.sopkafile\lib\choco\bare-metal-desktop.config"
}

if (-Not ((Get-WmiObject win32_computersystem).model -match "^VMware")) {
  choco install "$env:USERPROFILE\.sopkafile\lib\choco\bare-metal-desktop.config" --yes
  if ($LASTEXITCODE -ne 0) { throw "Unable to install packages: bare-metal-desktop" }
}

if ($install_developer_tools -eq 0) {
  choco install "$env:USERPROFILE\.sopkafile\lib\choco\developer-tools.config" --yes
  if ($LASTEXITCODE -ne 0) { throw "Unable to install packages: developer-tools" }
}

choco install "$env:USERPROFILE\.sopkafile\lib\choco\basic-tools.config" --yes
if ($LASTEXITCODE -ne 0) { throw "Unable to install packages: basic-tools" }


# Upgrade choco packages
if ("$env:CI" -ne "true") { # I don't need to update them in CI
  choco upgrade all --yes
  if ($LASTEXITCODE -ne 0) { throw "Unable to upgrade installed choco packages" }
}


# Configure developer tools
if ($install_developer_tools -eq 0) {
  # ssh-agent
  Set-Service -Name ssh-agent -StartupType Automatic
  Set-Service -Name ssh-agent -Status Running
}
