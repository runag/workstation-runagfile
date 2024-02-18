<!--
Copyright 2012-2022 Rùnag project contributors

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


## Deploy workstation on MacOS 

```sh
bash <(curl -Ssf https://raw.githubusercontent.com/runag/runag/main/deploy.sh) add runag/workstation-runagfile run
```


## Deploy workstation on Windows 

### 1. First stage deploy script (in powershell)

Start PowerShell as administrator, run the following and wait for it to complete:

```sh
iwr -UseBasicParsing "https://raw.githubusercontent.com/runag/workstation-runagfile/main/deploy.ps1" | iex
```

That script will do the following:

> 1. Installs chocolatey
> 2. Installs git
> 3. Clones [rùnag](https://github.com/runag/runag) and [workstation rùnagfile](https://github.com/runag/workstation-runagfile) repositories
> 4. Installs packages from those lists:
>    * [bare-metal-desktop.config](lib/choco/bare-metal-desktop.config) (if not in virtual machine)
>    * [developer-tools.config](lib/choco/developer-tools.config) (you will be asked if it's needed)
>    * [basic-tools.config](lib/choco/basic-tools.config)
> 7. Upgrades all installed choco packages
> 8. Sets ssh-agent service startup type to automatic and runs it
> 9. Installs MSYS2 and MINGW development toolchain for use in ruby's gems compilation
> 11. Installs pass (by pacman) and makes a symlink to it

### 2. Second stage deploy script (in bash)

At this point, Git Bash should be installed by the first script. Start Git Bash as your regular user and run the following:

```sh
~/.runag/bin/runag
```

Select from menu things that you need.


## Deploy tidy machine on Windows 

Start PowerShell as administrator, run the following and wait for it to complete:

```sh
iwr -UseBasicParsing "https://raw.githubusercontent.com/runag/workstation-runagfile/main/deploy-tidy.ps1" | iex
```


## Password Store

```
Password Store
├── backup
│   ├── profiles
│   │   └── workstation
│   │       ├── password
│   │       └── repositories
│   │           └── default
│   └── remotes
│       └── my-backup-server
│           ├── config
│           ├── config.linux
│           ├── id_ed25519
│           ├── id_ed25519.pub
│           ├── known_hosts
│           └── type
└── identity
    └── my
        ├── git
        │   ├── signing-key
        │   ├── user-email
        │   └── user-name
        ├── github
        │   ├── personal-access-token
        │   └── username
        ├── host-cifs
        │   └── credentials
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
        └── tailscale
            └── authkey
```

## If you fork this

1. Please go to [deploy.ps1](deploy.ps1) and find "If you forked this"


## License

[Apache License, Version 2.0](LICENSE).

## Contributing

Please check [CONTRIBUTING](CONTRIBUTING.md) file for details.
