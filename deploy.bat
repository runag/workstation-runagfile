@echo off

curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/main/deploy.ps1 -o "%USERPROFILE%\.deploy.ps1" || echo "Unable to download deploy.ps1" && exit /B

powershell -Command "Start-Process powershell \"-ExecutionPolicy Bypass -NoExit -Command `\"%USERPROFILE%\.deploy.ps1`\"\" -Wait -Verb RunAs"
