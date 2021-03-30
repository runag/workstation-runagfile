$ErrorActionPreference = "Stop"

$polar_question  = '&Yes', '&No'

$install_developer_tools = $Host.UI.PromptForChoice("Install developer-tools?", "", $polar_question, 0)
$install_gamer_tools = $Host.UI.PromptForChoice("Install packages: gamer-tools?", "", $polar_question, 0)
$install_pdf_tools = $Host.UI.PromptForChoice("Install packages: pdf-tools?", "", $polar_question, 1)
$install_remote_control = $Host.UI.PromptForChoice("Install packages: remote-control?", "", $polar_question, 1)
$install_russian_teleconferencing = $Host.UI.PromptForChoice("Install packages: russian-teleconferencing?", "", $polar_question, 1)

# scoop packages
scoop install restic
if ($LASTEXITCODE -ne 0) {
  throw "Unable to install restic"
}

if (-Not ((Get-WmiObject win32_computersystem).model -match "^VMware")) {
  choco install "$PSScriptRoot\packages\bare-metal-desktop.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: bare-metal-desktop"
  }
}

choco install "$PSScriptRoot\packages\basic-utilities.config" --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to install packages: basic-utilities"
}

if ($install_developer_tools -eq 0) {
  choco install "$PSScriptRoot\packages\developer-tools.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: developer-tools"
  }
}

if ($install_gamer_tools -eq 0) {
  choco install "$PSScriptRoot\packages\gamer-tools.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: gamer-tools"
  }
}

if ($install_pdf_tools -eq 0) {
  choco install "$PSScriptRoot\packages\pdf-tools.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: pdf-tools"
  }
}

if ($install_remote_control -eq 0) {
  choco install "$PSScriptRoot\packages\remote-control.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: remote-control"
  }
}

if ($install_russian_teleconferencing -eq 0) {
  choco install "$PSScriptRoot\packages\russian-teleconferencing.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: russian-teleconferencing"
  }
}

choco upgrade all --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to upgrade installed choco packages"
}
