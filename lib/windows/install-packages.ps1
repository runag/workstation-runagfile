$ErrorActionPreference = "Stop"

if (Test-Path "$PSScriptRoot\packages.config") {
  choco install "$PSScriptRoot\packages.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages"
  }
}

if (-Not ((Get-WmiObject win32_computersystem).model -match "^VMware")) {
  if (Test-Path "$PSScriptRoot\packages-bare-metal-desktop.config") {
    choco install "$PSScriptRoot\packages-bare-metal-desktop.config" --yes
    if ($LASTEXITCODE -ne 0) {
      throw "Unable to install desktop packages"
    }
  }
}

choco upgrade all --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to upgrade installed packages"
}
