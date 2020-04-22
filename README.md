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

Any time later after the initial deployment you may wish to run those scripts again to update the system.

# Linux workstation

```sh
bash <(wget -qO- https://raw.githubusercontent.com/senotrusov/my-computer-deploy/master/bin/install-and-deploy)
```

# MacOS

## 1. Install git and developer tools

1. Open console
2. Type ``git``
3. Confirm installation

## 2. Deploy workstation
```sh
bash <(curl -Ssf https://raw.githubusercontent.com/senotrusov/my-computer-deploy/master/bin/install-and-deploy)
```

## 3. Macs Fan Control configuration

1. Configure fan to be based on PECI sensor, 70-80 temperature range
2. In preferences enable "Autostart minimized with system"

## Secret items which are expected to be found in a Bitwarden

The names should be as the following:

* ``my current ssh private key``  
* ``my current ssh public key``  
* ``my current password for ssh private key``  
* ``my github personal access token``  
* ``sublime text 3 license``  
* ``data-pi onion address``  
* ``kelly disk key``  

# Contributing

## Please check shell scripts before commiting any changes
```sh
test/run-code-checks
```
