$ErrorActionPreference = "Stop"

# Ask a question
if ("$env:GITHUB_ACTIONS" -eq "true") {
  $install_developer_tools = 0
} else {
  $polar_question = "&Yes", "&No"
  $install_developer_tools = $Host.UI.PromptForChoice("Install developer tools?", "", $polar_question, 0)
}


# Allow untrusted script execution
Set-ExecutionPolicy Bypass -Scope Process -Force


# Install scoop
if (-Not (Get-Command "scoop" -ErrorAction SilentlyContinue)) {
  # Set-ExecutionPolicy RemoteSigned -scope CurrentUser -Force
  Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://get.scoop.sh")
}

if (-Not (Get-Command "scoop" -ErrorAction SilentlyContinue)) {
  throw "Unable to find scoop"
}


# Install and configure chocolatey
if (-Not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
  # Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://chocolatey.org/install.ps1"))
}

if (-Not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
  throw "Unable to find choco"
}

choco feature enable -n allowGlobalConfirmation
if ($LASTEXITCODE -ne 0) { throw "Unable to set chocolatey feature" }

if ("$env:GITHUB_ACTIONS" -eq "true") {
  choco feature disable -n showDownloadProgress
  if ($LASTEXITCODE -ne 0) { throw "Unable to set chocolatey feature" }
}


# Install and configure git
if (-not (Test-Path "C:\Program Files\Git\bin\git.exe")) {
  choco install git --yes
  if ($LASTEXITCODE -ne 0) { throw "Unable to install git" }
}

if (-not (Test-Path "C:\Program Files\Git\bin\git.exe")) {
  throw "Unable to find git"
}

& "C:\Program Files\Git\bin\git.exe" config --global core.autocrlf input
if ($LASTEXITCODE -ne 0) { throw "Unable to set git config" }


# Clone repositories
function Git-Clone-or-Pull($url, $dest){
  if (Test-Path -Path "$dest") {
    & "C:\Program Files\Git\bin\git.exe" -C "$dest" config remote.origin.url "$url"
    if ($LASTEXITCODE -ne 0) { throw "Unable to change git remote origin url" }
  
    & "C:\Program Files\Git\bin\git.exe" -C "$dest" pull
    if ($LASTEXITCODE -ne 0) { throw "Unable to git pull" }
  } else {
    & "C:\Program Files\Git\bin\git.exe" clone "$url" "$dest"
    if ($LASTEXITCODE -ne 0) { throw "Unable to git pull" }
  }
}

Git-Clone-or-Pull "https://github.com/senotrusov/sopka.git" "$env:USERPROFILE\.sopka"
Git-Clone-or-Pull "https://github.com/senotrusov/sopkafile.git" "$env:USERPROFILE\.sopkafile"


# Install scoop packages
scoop install restic
if ($LASTEXITCODE -ne 0) { throw "Unable to install restic" }


# Install choco packages
if ("$env:GITHUB_ACTIONS" -ne "true") { # gpg4win hangs forever in CI
  if (-Not ((Get-WmiObject win32_computersystem).model -match "^VMware")) {
    choco install "$env:USERPROFILE\.sopkafile\lib\windows\packages\bare-metal-desktop.config" --yes
    if ($LASTEXITCODE -ne 0) { throw "Unable to install packages: bare-metal-desktop" }
  }
}

if ($install_developer_tools -eq 0) {
  choco install "$env:USERPROFILE\.sopkafile\lib\windows\packages\developer-tools.config" --yes
  if ($LASTEXITCODE -ne 0) { throw "Unable to install packages: developer-tools" }
}

choco install "$env:USERPROFILE\.sopkafile\lib\windows\packages\basic-utilities.config" --yes
if ($LASTEXITCODE -ne 0) { throw "Unable to install packages: basic-utilities" }


# Upgrade choco packages
if ("$env:GITHUB_ACTIONS" -ne "true") { # I don't need to update them in CI
  choco upgrade all --yes
  if ($LASTEXITCODE -ne 0) { throw "Unable to upgrade installed choco packages" }
}


# Configure developer tools
if ($install_developer_tools -eq 0) {
  # ssh-agent
  Set-Service -Name ssh-agent -StartupType Automatic
  Set-Service -Name ssh-agent -Status Running
}
