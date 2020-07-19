@echo off

cd %USERPROFILE% || echo "Unable to change directory" && exit /B

curl -Ssf https://raw.githubusercontent.com/senotrusov/stan-computer-deploy/master/deploy.ps1 -o .deploy.ps1 || echo "Unable to download deploy.ps1" && exit /B

powershell -Command "Start-Process powershell \"-ExecutionPolicy Bypass -NoExit -Command %USERPROFILE%\.deploy.ps1\" -Wait -Verb RunAs"
