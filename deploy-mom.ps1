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

if (-not (Test-Path "$env:USERPROFILE\.packages.config")) {
  throw "Unable to find $env:USERPROFILE\.packages.config"
}

choco install "$env:USERPROFILE\.packages.config" --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to install packages"
}

choco upgrade all --yes
if ($LASTEXITCODE -ne 0) {
  throw "Unable to upgrade installed packages"
}
