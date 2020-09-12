$ErrorActionPreference = "Stop"

if (-Not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
  Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

  choco feature enable -n allowGlobalConfirmation
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to set chocolatey feature"
  }
}

if (-Not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
  throw "Unable to find chocolatey"
}

choco upgrade all --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to upgrade installed packages"
}

choco install "$env:USERPROFILE\.bare-metal-desktop.config" --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to install packages: bare-metal-desktop"
}

choco install "$env:USERPROFILE\.basic-utilities.config" --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to install packages: basic-utilities"
}

choco install "$env:USERPROFILE\.non-developer.config" --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to install packages: non-developer"
}

$yes_no  = '&Yes', '&No'

$choice = $Host.UI.PromptForChoice("Install packages: gamer?", "", $yes_no, 0)
if ($choice -eq 0) {
  choco install "$env:USERPROFILE\.gamer.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: gamer"
  }
}

$choice = $Host.UI.PromptForChoice("Install packages: pdf-tools?", "", $yes_no, 0)
if ($choice -eq 0) {
  choco install "$env:USERPROFILE\.pdf-tools.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: pdf-tools"
  }
}

$choice = $Host.UI.PromptForChoice("Install packages: remote-control?", "", $yes_no, 0)
if ($choice -eq 0) {
  choco install "$env:USERPROFILE\.remote-control.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: remote-control"
  }
}

$choice = $Host.UI.PromptForChoice("Install packages: russian-teleconferencing?", "", $yes_no, 0)
if ($choice -eq 0) {
  choco install "$env:USERPROFILE\.russian-teleconferencing.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: russian-teleconferencing"
  }
}
