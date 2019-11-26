# My computer deploy

A script to deploy my workstation on a freshly installed Linux or MacOS. Basically I run one command and after that my workstation is fully configured for me to use.

The script will do the following:

1. Installs the basic software I frequently use.
2. Installs my keys, passwords, software licenses. I keep them in the bitwarden database, this script puts SSH keys to the filesystem and passwords to the linux keychain, so I could connect to my remote servers and commit to my git repositories without entering any extra passwords besides system login one. Also this script enables gnome keyring access in TTY sessions to ease the use of SSH keys and git credentials in Sway WM.
3. Makes a few tweaks to the system and to the desktop software.
4. Installs a few shell aliases.
5. Installs configuration for the Sublime Text and Visual Studio Code. It also can put that configuration back from the workstation to the repository in case I changed it locally.
6. With an extra environment flag DEPLOY_SWAY it installs Sway WM, my Sway configuration and few related software packages.

This script can be run multiple times to produce a system which is up-to date with the recent software updates and my configuration changes.

The file ``config.sh`` contains my name and email to use in configuration. In the unlikely event someone will fork that script to configure his own computer this is where you could put your name and email.

# Linux workstation

## a) Deploy ubuntu workstation
```sh
cd ~ && if ! command -v git; then sudo apt update && sudo apt install -y git; fi && if [ -d my-computer-deploy ]; then cd my-computer-deploy && git pull; else git clone https://github.com/senotrusov/my-computer-deploy.git && cd my-computer-deploy; fi && bin/deploy-ubuntu-workstation
```

## b) Just clone this script to a new machine
```sh
cd ~ && if ! command -v git; then sudo apt update && sudo apt install -y git; fi && if [ -d my-computer-deploy ]; then cd my-computer-deploy && git pull; else git clone https://github.com/senotrusov/my-computer-deploy.git && cd my-computer-deploy; fi && ls -1 bin/*
```

# Syncthing node on a Raspberry PI

There is also a script to deploy a Syncthing node on a Raspberry PI, but it's not yet fully complete.

```sh
cd ~ && if ! command -v git; then sudo apt update && sudo apt install -y git; fi && if [ -d my-computer-deploy ]; then cd my-computer-deploy && git pull; else git clone https://github.com/senotrusov/my-computer-deploy.git && cd my-computer-deploy; fi && bin/deploy-data-pi
```

# MacOS

## 1. Install git and developer tools

1. Open console
2. Type ``git``
3. Confirm installation

## 2a) Deploy workstation
```sh
cd ~ && if [ -d my-computer-deploy ]; then cd my-computer-deploy && git pull; else git clone https://github.com/senotrusov/my-computer-deploy.git && cd my-computer-deploy; fi && bin/deploy-macos-workstation
```

## 2b) Deploy non-developer workstation
```sh
cd ~ && if [ -d my-computer-deploy ]; then cd my-computer-deploy && git pull; else git clone https://github.com/senotrusov/my-computer-deploy.git && cd my-computer-deploy; fi && bin/deploy-macos-non-developer-workstation
```

## Macs Fan Control configuration

1. Configure fan to be based on PECI sensor, 60-80 temperature range
2. In preferences enable "Autostart minimized with system"

# What's inside

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


## Secret items which are expected to be found in a Bitwarden

The names should be as the following:

* ``my current ssh private key``  
* ``my current ssh public key``  
* ``my current password for ssh private key``  
* ``my github personal access token``  
* ``sublime text 3 license``  
* ``data-pi onion address``  
* ``kelly disk key``  

# Footnotes

## Please check shell scripts before commiting any changes
```sh
test/run-code-checks
```
