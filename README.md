<!--
Copyright 2012-2022 Stanislav Senotrusov <stan@senotrusov.com>

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

# 🚞 Runagfile to configure my workstation

A collection of scripts to deploy my workstation. I hope other people may find them useful.

I run them on a freshly installed Linux, MacOS, or Windows to install and configure software and credentials. Scripts are idempotent, they could be run multiple times. There is also a library, [Runag](https://github.com/senotrusov/sopka), that helps this scripts to look nice and declarative.

![Runag menu screenshot](docs/sopka-menu-screenshot.png)


## Deploy workstation on Linux

```sh
bash <(wget -qO- https://raw.githubusercontent.com/senotrusov/sopka/main/deploy.sh) add senotrusov/workstation-sopkafile run
```


## Deploy workstation on MacOS 

```sh
bash <(curl -Ssf https://raw.githubusercontent.com/senotrusov/sopka/main/deploy.sh) add senotrusov/workstation-sopkafile run
```


## Deploy workstation on Windows 

### 1. First stage deploy script (in powershell)

Start PowerShell as administrator, run the following and wait for it to complete:

```sh
iwr -UseBasicParsing "https://raw.githubusercontent.com/senotrusov/workstation-sopkafile/main/deploy.ps1" | iex
```

That script will do the following:

1. Installs chocolatey
2. Installs git
3. Clones [sopka](https://github.com/senotrusov/sopka) and [workstation-sopkafile](https://github.com/senotrusov/workstation-sopkafile) repositories
4. Installs packages from those lists:
    * [bare-metal-desktop.config](lib/choco/bare-metal-desktop.config) (if not in virtual machine)
    * [developer-tools.config](lib/choco/developer-tools.config) (you will be asked if it's needed)
    * [basic-tools.config](lib/choco/basic-tools.config)
7. Upgrades all installed choco packages
8. Sets ssh-agent service startup type to automatic and runs it
9. Installs MSYS2 and MINGW development toolchain for use in ruby's gems compilation
10. Installs my lovely file-digests gem
11. Install pass (by pacman) and symlinks to it

### 2. Second stage deploy script (in bash)

At this point, Git Bash should be installed by the first script. Start Git Bash as your regular user and run the following:

```sh
~/.sopka/bin/sopka
```

Select from menu things that you need.

## Password Store

```
Password Store
├── backup
│   ├── profiles
│   │   └── workstation
│   │       ├── password
│   │       └── repositories
│   │           ├── default
│   │           └── offline
│   └── remotes
│       └── personal-backup-server
│           ├── config
│           ├── id_ed25519
│           ├── id_ed25519.pub
│           ├── known_hosts
│           └── type
├── checksums.txt
├── deployment-repository
│   └── personal
├── identity
│   └── personal
│       ├── git
│       │   ├── signing-key
│       │   ├── user-email
│       │   └── user-name
│       ├── github
│       │   ├── personal-access-token
│       │   └── username
│       ├── npm
│       │   └── access-token
│       ├── rubygems
│       │   └── credentials
│       └── ssh
│           ├── id_ed25519
│           └── id_ed25519.pub
├── sublime-merge
│   └── personal
├── sublime-text
│   └── personal
├── tailscale
│   └── personal
└── windows-cifs
    └── personal
```

## If you fork this script

1. Please go to [deploy.ps1](deploy.ps1) and find "If you forked this script"


## Contributing

Please use [ShellCheck](https://www.shellcheck.net/).

I mostly follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html).
