@echo off

cd %USERPROFILE%

IF NOT EXIST C:\"Program Files"\Git\bin\sh.exe (
  IF NOT EXIST .PortableGit\bin\sh.exe (
    curl -LSsf https://github.com/git-for-windows/git/releases/download/v2.27.0.windows.1/PortableGit-2.27.0-64-bit.7z.exe -o .PortableGit.exe || echo "Unable to download PortableGit" && exit /B

    start /wait .PortableGit.exe -o".PortableGit" -y
    REM TODO: Obtain exit status of .PortableGit.exe

    del .PortableGit.exe || echo "Unable to delete PortableGit archive" && exit /B
  )
)

REM Without "start" sh.exe will brake current terminal

IF EXIST C:\"Program Files"\Git\bin\sh.exe (
  start /wait C:\"Program Files"\Git\bin\sh.exe -c "bash <(curl -Ssf https://raw.githubusercontent.com/senotrusov/stan-computer-deploy/master/deploy.sh) || echo Abnormal termination; echo Press ENTER to continue; read"
) ELSE (
  start /wait .PortableGit\bin\sh.exe -c "bash <(curl -Ssf https://raw.githubusercontent.com/senotrusov/stan-computer-deploy/master/deploy.sh) || echo Abnormal termination; echo Press ENTER to continue; read"
)
