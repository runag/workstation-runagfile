$ErrorActionPreference = "Stop"

$polar_question  = '&Yes', '&No'

$install_developer_tools = $Host.UI.PromptForChoice("Install developer tools?", "", $polar_question, 0)


# install scoop
if (-Not (Get-Command "scoop" -ErrorAction SilentlyContinue)) {
  # Set-ExecutionPolicy RemoteSigned -scope CurrentUser -Force
  Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
}

if (-Not (Get-Command "scoop" -ErrorAction SilentlyContinue)) {
  throw "Unable to find scoop"
}


# install chocolatey
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
  throw "Unable to find choco"
}

# git
if (-not (Test-Path "C:\Program Files\Git\bin\sh.exe")) {
  choco install git --yes
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to install git"
  }
}

if (-not (Test-Path "C:\Program Files\Git\bin\sh.exe")) {
    throw "Unable to find git"
}

if ($install_developer_tools -eq 0) {
  # ssh-agent
  Set-Service -Name ssh-agent -StartupType Automatic
  Set-Service -Name ssh-agent -Status Running

  # bitwarden-cli
  if (-Not (Get-Command "bw" -ErrorAction SilentlyContinue)) {
    choco install bitwarden-cli --yes
    if ($LASTEXITCODE -ne 0) {
      throw "Unable to install bitwarden-cli"
    }
  }

  # jq
  if (-Not (Get-Command "jq" -ErrorAction SilentlyContinue)) {
    choco install jq --yes
    if ($LASTEXITCODE -ne 0) {
      throw "Unable to install jq"
    }
  }

  # vscode
  if (-not (Test-Path "C:\Program Files\Microsoft VS Code\bin\code.cmd")) {
    choco install vscode --yes
    if ($LASTEXITCODE -ne 0) {
      throw "Unable to install vscode"
    }
  }

  # check if required tools are all installed
  if (-not (
    (Get-Command "bw" -ErrorAction SilentlyContinue) -and
    (Get-Command "jq" -ErrorAction SilentlyContinue) -and
    (Test-Path "C:\Program Files\Microsoft VS Code\bin\code.cmd")
    )) {
    throw "Unable to find all dependencies"
  }
}


# run shell script
$windowsDeployWorkstation = Start-Process "C:\Program Files\Git\bin\sh.exe" "-c 'bash <(curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/main/deploy.sh); exitStatus=`$?; if [ `$exitStatus != 0 ]; then echo Abnormal termination >&2; fi; echo Press ENTER to close the window >&2; read; exit `$exitStatus;'" -Wait -PassThru -Credential "$env:USERNAME"

if ($windowsDeployWorkstation.ExitCode -ne 0) {
  throw "Error running windows::deploy-workstation"
}


# install packages
$installPackagesPath = "$env:USERPROFILE\.sopkafile\lib\windows\install-packages.ps1"

if (-not (Test-Path "$installPackagesPath")) {
  throw "Unable to find install-packages script"
}

# TODO: obtain exit status
& "$installPackagesPath"
