$ErrorActionPreference = "Stop"

$polar_question  = '&Yes', '&No'

$install_developer_tools = $Host.UI.PromptForChoice("Install developer-tools?", "", $polar_question, 0)

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

choco upgrade all --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to upgrade installed choco packages"
}
