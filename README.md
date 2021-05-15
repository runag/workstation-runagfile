<!--
Copyright 2012-2021 Stanislav Senotrusov <stan@senotrusov.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->
# 🚞 Sopkafile to configure my workstation

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

## Linux

```sh
bash <(wget -qO- https://raw.githubusercontent.com/senotrusov/sopkafile/main/deploy.sh)
```

## MacOS

```sh
bash <(curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/main/deploy.sh)
```

## Windows

```sh
curl -Ssf https://raw.githubusercontent.com/senotrusov/sopkafile/main/deploy.bat -o .deploy.bat && .deploy.bat
```

<!--
## my-storage-vm

```sh
sopka my-storage-vm::deploy
# reboot
# copy key to a home directory
sopka backup::stan-documents borg::import-key
sopka backup::stan-documents borg::systemd::enable-timer
```
-->

## Secret items which are expected to be found in a Bitwarden

Record names should be as the following:

<!-- # bitwarden-object: see list below -->

```
"my borg storage ssh private key"
"my borg storage ssh public key"
"my github personal access token"
"my microsoft account"
"my password for ssh private key"
"my ssh private key"
"my ssh public key"
"stan-documents backup passphrase"
"stan-documents backup storage"
"sublime text 3 license"
```

## Contributing

### Please check shell scripts before commiting any changes
```sh
test/run-code-checks.sh
```
