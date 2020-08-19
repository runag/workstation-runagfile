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

Set-Service -Name ssh-agent -StartupType Automatic
Set-Service -Name ssh-agent -Status Running

if (-Not (Get-Command "bw" -ErrorAction SilentlyContinue)) {
  choco install bitwarden-cli --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install bitwarden-cli"
  }
}

if (-Not (Get-Command "jq" -ErrorAction SilentlyContinue)) {
  choco install jq --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install jq"
  }
}

if (-not (Test-Path "C:\Program Files\Microsoft VS Code\bin\code.cmd")) {
  choco install vscode --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install vscode"
  }
}

if (-not (Test-Path "C:\Program Files\Git\bin\sh.exe")) {
  choco install git --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install git"
  }
}

if (-not (
  (Get-Command "bw" -ErrorAction SilentlyContinue) -and
  (Get-Command "jq" -ErrorAction SilentlyContinue) -and
  (Test-Path "C:\Program Files\Microsoft VS Code\bin\code.cmd") -and
  (Test-Path "C:\Program Files\Git\bin\sh.exe")
  )) {
  throw "Unable to find all dependencies"
}

$windowsDeployWorkstation = Start-Process "C:\Program Files\Git\bin\sh.exe" "-c 'bash <(curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/master/deploy.sh); exitStatus=`$?; if [ `$exitStatus != 0 ]; then echo Abnormal termination >&2; fi; echo Press ENTER to close the window >&2; read; exit `$exitStatus;'" -Wait -PassThru -Credential "$env:USERNAME"

if ($windowsDeployWorkstation.ExitCode -ne 0) {
  throw "Error running windows::deploy-workstation"
}

$installPackagesPath = "$env:USERPROFILE\.sopkafile\lib\windows\install-packages.ps1"

if (Test-Path "$installPackagesPath") {
  # TODO: obtain exit status
  & "$installPackagesPath"
}
