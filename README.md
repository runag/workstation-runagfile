# 🚞 Sopkafile to configure my personal computers

A script to configure my workstation. I run it on a freshly installed Linux, MacOS, or Windows.

It will do the following:

1. Installs the basic software I frequently use.
2. Installs my keys, passwords, software licenses (I keep them in the bitwarden database)
	* Puts SSH keys to the filesystem and passwords to the linux keychain.
3. Makes a few tweaks to the system and to the desktop software.
4. Installs a few shell aliases.
5. Installs configuration for the Sublime Text and Visual Studio Code (there is also a script to keep configuration in the repository up to date with the local changes).

This script is idempotent. It can be run multiple times to produce a system which is up-to date with the recent software updates and with my configuration changes.

The file ``lib/config.sh`` contains my name and email to use in configuration. If you'll fork this script, please remove them.

## Linux workstation

```sh
bash <(wget -qO- https://raw.githubusercontent.com/senotrusov/stan-computer-deploy/master/deploy.sh)
```

## MacOS

```sh
bash <(curl -Ssf https://raw.githubusercontent.com/senotrusov/stan-computer-deploy/master/deploy.sh)
```

## Windows

```sh
curl -Ssf https://raw.githubusercontent.com/senotrusov/stan-computer-deploy/master/deploy.bat -o .deploy.bat && .deploy.bat
```

## Secret items which are expected to be found in a Bitwarden

Record names should be as the following:

```
my current ssh private key
my current ssh public key
my current password for ssh private key
my github personal access token
sublime text 3 license
```

## Contributing

### Please check shell scripts before commiting any changes
```sh
test/run-code-checks.sh
```
