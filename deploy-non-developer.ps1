$ErrorActionPreference = "Stop"

$yes_no  = '&Yes', '&No'

$choice_gamer = $Host.UI.PromptForChoice("Install packages: gamer?", "", $yes_no, 0)
$choice_pdf_tools = $Host.UI.PromptForChoice("Install packages: pdf-tools?", "", $yes_no, 1)
$choice_remote_control = $Host.UI.PromptForChoice("Install packages: remote-control?", "", $yes_no, 1)
$choice_russian_teleconferencing = $Host.UI.PromptForChoice("Install packages: russian-teleconferencing?", "", $yes_no, 1)

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

choco install "$env:USERPROFILE\.sopkafile\bare-metal-desktop.config" --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to install packages: bare-metal-desktop"
}

choco install "$env:USERPROFILE\.sopkafile\basic-utilities.config" --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to install packages: basic-utilities"
}

choco install "$env:USERPROFILE\.sopkafile\non-developer.config" --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to install packages: non-developer"
}

if ($choice_gamer -eq 0) {
  choco install "$env:USERPROFILE\.sopkafile\gamer.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: gamer"
  }
}

if ($choice_pdf_tools -eq 0) {
  choco install "$env:USERPROFILE\.sopkafile\pdf-tools.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: pdf-tools"
  }
}

if ($choice_remote_control -eq 0) {
  choco install "$env:USERPROFILE\.sopkafile\remote-control.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: remote-control"
  }
}

if ($choice_russian_teleconferencing -eq 0) {
  choco install "$env:USERPROFILE\.sopkafile\russian-teleconferencing.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: russian-teleconferencing"
  }
}
