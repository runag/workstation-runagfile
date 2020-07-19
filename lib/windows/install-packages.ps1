$ErrorActionPreference = "Stop"

if (Test-Path "$PSScriptRoot\packages.config") {
  choco install "$PSScriptRoot\packages.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages"
  }
}

if (-Not ((Get-WmiObject win32_computersystem).model -match "^VMware")) {
  if (Test-Path "$PSScriptRoot\packages-desktop.config") {
    choco install "$PSScriptRoot\packages-desktop.config" --yes
    if ($LASTEXITCODE -ne 0) {
      throw "Unable to install desktop packages"
    }
  }
}
