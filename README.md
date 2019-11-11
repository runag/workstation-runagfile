# Linux

## Deploy ubuntu workstation one-liner
```sh
cd ~ && if ! command -v git; then sudo apt update && sudo apt install -y git; fi && if [ -d my-computer-deploy ]; then cd my-computer-deploy && git pull; else git clone https://github.com/senotrusov/my-computer-deploy.git && cd my-computer-deploy; fi && bin/deploy-ubuntu-workstation
```

## Deploy data pi one-liner
```sh
cd ~ && if ! command -v git; then sudo apt update && sudo apt install -y git; fi && if [ -d my-computer-deploy ]; then cd my-computer-deploy && git pull; else git clone https://github.com/senotrusov/my-computer-deploy.git && cd my-computer-deploy; fi && bin/deploy-data-pi
```

## Clone to a new machine one-liner
```sh
cd ~ && if ! command -v git; then sudo apt update && sudo apt install -y git; fi && if [ -d my-computer-deploy ]; then cd my-computer-deploy && git pull; else git clone https://github.com/senotrusov/my-computer-deploy.git && cd my-computer-deploy; fi && ls -1 bin/*
```

# MacOS

## 1. Install git and developer tools

1. Open console
2. Type ``git``
3. Confirm installation

## deploy-macos-workstation one-liner
```sh
cd ~ && if [ -d my-computer-deploy ]; then cd my-computer-deploy && git pull; else git clone https://github.com/senotrusov/my-computer-deploy.git && cd my-computer-deploy; fi && bin/deploy-macos-workstation
```

## deploy-macos-non-developer-workstation one-liner
```sh
cd ~ && if [ -d my-computer-deploy ]; then cd my-computer-deploy && git pull; else git clone https://github.com/senotrusov/my-computer-deploy.git && cd my-computer-deploy; fi && bin/deploy-macos-non-developer-workstation
```

## Macs Fan Control

1. Configure fan to be based on PECI sensor, 60-80 temperature range
2. In preferences enable "Autostart minimized with system"


## Deployment scripts
```sh
bin/deploy-data-pi
bin/deploy-macos-non-developer-workstation
bin/deploy-macos-workstation
bin/deploy-ubuntu-workstation
```


## Merge configs between the live system and the deploy repository
```sh
bin/merge-workstation-configs
```


## Manual backups
```sh
bin/backup-polina-archive
bin/backup-stan-archive
```


## Deployment shell

Any time later after the initial deployment you may wish to run those scripts again to update the system.

For that please keep the original directory somewhere.

The command ``my-computer-deploy`` will be available as a shell alias after the initial deployment. Upon execution it will open a subshell that brings you to the directory that contains the initial deployment scripts. It's ``bin`` will be in that subshell's ``PATH``.


## Secret items which are stored in Bitwarden

The names should be as the following:

``my current ssh private key``  
``my current ssh public key``  
``my current password for ssh private key``  
``my github personal access token``
``Sublime Text 3 license``  
``data-pi onion address``  
``kelly disk key``  


## Please check shell scripts before commiting any changes
```sh
shellcheck bin/* *.sh **/*.sh
```
