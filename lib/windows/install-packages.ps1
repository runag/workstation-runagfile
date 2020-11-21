$ErrorActionPreference = "Stop"

if (-Not ((Get-WmiObject win32_computersystem).model -match "^VMware")) {
  if (Test-Path "$PSScriptRoot\packages\bare-metal-desktop.config") {
    choco install "$PSScriptRoot\packages\bare-metal-desktop.config" --yes
    if ($LASTEXITCODE -ne 0) {
      throw "Unable to install packages: bare-metal-desktop"
    }
  }
}

if (Test-Path "$PSScriptRoot\packages\basic-utilities.config") {
  choco install "$PSScriptRoot\packages\basic-utilities.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: basic-utilities"
  }
}

if (Test-Path "$PSScriptRoot\packages\developer.config") {
  choco install "$PSScriptRoot\packages\developer.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: developer"
  }
}

if (Test-Path "$PSScriptRoot\packages\gamer.config") {
  choco install "$PSScriptRoot\packages\gamer.config" --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install packages: gamer"
  }
}

choco upgrade all --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to upgrade installed packages"
}

# scoop packages
scoop install restic
if ($LASTEXITCODE -ne 0) {
  throw "Unable to install restic"
}
