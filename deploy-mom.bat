@echo off

curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/master/deploy-mom.ps1 -o "%USERPROFILE%\.deploy.ps1" || echo "Unable to download deploy.ps1" && exit /B
curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/master/lib/windows/packages-mom.config -o "%USERPROFILE%\.packages.config" || echo "Unable to download packages.config" && exit /B

powershell -Command "Start-Process powershell \"-ExecutionPolicy Bypass -NoExit -Command `\"%USERPROFILE%\.deploy.ps1`\"\" -Wait -Verb RunAs"
