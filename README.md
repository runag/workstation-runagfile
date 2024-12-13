<!--
Copyright 2012-2024 Rùnag project contributors

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

# Rùnagfile to configure a workstation

🧡 A script to deploy a workstation.

* It could be run on a freshly installed Linux, MacOS, or Windows.
* It installs and configures software, credentials, and backups.
* It is idempotent, it could be run multiple times to produce up-to date configuration.

I have made some effort to ensure that this script does not contain personal identifiable information. All such information is stored in the [pass](https://www.passwordstore.org/) database, which is imported from external media when deploying a workstation.

There is a library, [💜 Rùnag](https://github.com/runag/runag), that allows the code here to be declarative and concise.

## Deploy workstation on Linux

```sh
bash <(wget -qO- https://raw.githubusercontent.com/runag/runag/main/deploy.sh) add runag/workstation-runagfile run
```


## Deploy workstation on Linux in KVM (useful for testing)

**On host machine**

This step will copy your `~/.password-store` and `~/.gnupg` keys to `~/.runag/.virt-deploy-keys` directory, and after consecutive steps your keys will be accessible from the guest machine. Please make sure you understand implications of that.

```
mkdir ~/.runag/.virt-deploy-keys
runag workstation::linux::deploy_virt_keys
```

**In virt-manager**

1. Enable shared memory

2. Create Filesystem

```
Driver: virtiofs
Source path: ~/.runag # replace ~ with absolute path!
Target path: runag
```

**On guest machine**

```sh
sudo mount -m -t virtiofs runag ~/.runag
~/.runag/bin/runag
```

**Modify `/etc/fstab` if you want to keep `.runag` mount after reboot**

```sh
# /etc/fstab

# replace ~ with absolute path!
runag  ~/.runag  virtiofs  defaults  0  0
```

## Deploy workstation on MacOS 

```sh
bash <(curl -Ssf https://raw.githubusercontent.com/runag/runag/main/deploy.sh) add runag/workstation-runagfile run
```


## Deploy Windows machine

Start PowerShell as administrator, run the following and wait for it to complete:

```sh
iwr -UseBasicParsing "https://raw.githubusercontent.com/runag/workstation-runagfile/main/deploy.ps1" | iex
```


## Password Store

```
backup
├── passwords
│   └── workstation
├── remotes
│   └── sftp
│       └── backup-server
│           ├── config
│           ├── config.linux
│           ├── id_ed25519
│           ├── id_ed25519.pub
│           └── known_hosts
└── repositories
    └── workstation

identity/my
├── git
│   ├── signing-key
│   ├── user-email
│   └── user-name
├── github
│   ├── personal-access-token
│   └── username
├── npm
│   └── access-token
├── runag
│   └── runagfiles
├── rubygems
│   └── credentials
├── ssh
│   ├── config
│   ├── id_ed25519
│   └── id_ed25519.pub
├── sublime-merge
│   └── license
├── sublime-text
│   └── license
├── tailscale
│   └── authkey
└── wifi
    └── home
        ├── password
        └── ssid
```

### Generate and save SSH key to the password store

```sh
# Fill this
ssh_keyfile="id_ed25519"
ssh_comment=""
ssh_passphrase=""
pass_path="identity/my/ssh"

ssh-keygen -t ed25519 -C "${ssh_comment}" -f "${ssh_keyfile}" -N "${ssh_passphrase}"

{ echo "${ssh_passphrase}"; cat "${ssh_keyfile}"; } | pass insert --multiline "${pass_path}/${ssh_keyfile}"
pass insert --multiline "${pass_path}/${ssh_keyfile}.pub" <"${ssh_keyfile}.pub"
```

## If you fork this

You may wish to change some paths:

1. This [README](README.md) file, `runag/workstation-runagfile` and maybe `runag/runag` if you forked it as well.

## License

[Apache License, Version 2.0](LICENSE).

## Contributing

Please check [CONTRIBUTING](CONTRIBUTING.md) file for details.
