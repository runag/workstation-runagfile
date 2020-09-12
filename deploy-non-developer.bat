@echo off

curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/master/deploy-non-developer.ps1 -o "%USERPROFILE%\.deploy.ps1" || echo "Unable to download deploy.ps1" && exit /B

curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/master/lib/windows/packages/bare-metal-desktop.config -o "%USERPROFILE%\.bare-metal-desktop.config" || echo "Unable to download file bare-metal-desktop.config" && exit /B
curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/master/lib/windows/packages/basic-utilities.config -o "%USERPROFILE%\.basic-utilities.config" || echo "Unable to download file basic-utilities.config" && exit /B
curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/master/lib/windows/packages/gamer.config -o "%USERPROFILE%\.gamer.config" || echo "Unable to download file gamer.config" && exit /B
curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/master/lib/windows/packages/non-developer.config -o "%USERPROFILE%\.non-developer.config" || echo "Unable to download file non-developer.config" && exit /B
curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/master/lib/windows/packages/pdf-tools.config -o "%USERPROFILE%\.pdf-tools.config" || echo "Unable to download file pdf-tools.config" && exit /B
curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/master/lib/windows/packages/remote-control.config -o "%USERPROFILE%\.remote-control.config" || echo "Unable to download file remote-control.config" && exit /B
curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/master/lib/windows/packages/russian-teleconferencing.config -o "%USERPROFILE%\.russian-teleconferencing.config" || echo "Unable to download file russian-teleconferencing.config" && exit /B

powershell -Command "Start-Process powershell \"-ExecutionPolicy Bypass -NoExit -Command `\"%USERPROFILE%\.deploy.ps1`\"\" -Wait -Verb RunAs"
