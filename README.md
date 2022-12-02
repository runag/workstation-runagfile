<!--
Copyright 2012-2022 Runag project contributors

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

# 🛷 Runagfile to configure a workstation

A collection of scripts to deploy a workstation.

It could be run on a freshly installed Linux, MacOS, or Windows to install and configure software and credentials.

Scripts are idempotent, they could be run multiple times to produce up-to date configuration.

There is a library, [Runag](https://github.com/runag/runag), that allows this scripts to be declarative and concise.


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

1. Installs chocolatey
2. Installs git
3. Clones [runag](https://github.com/runag/runag) and [workstation-runagfile](https://github.com/runag/workstation-runagfile) repositories
4. Installs packages from those lists:
    * [bare-metal-desktop.config](lib/choco/bare-metal-desktop.config) (if not in virtual machine)
    * [developer-tools.config](lib/choco/developer-tools.config) (you will be asked if it's needed)
    * [basic-tools.config](lib/choco/basic-tools.config)
7. Upgrades all installed choco packages
8. Sets ssh-agent service startup type to automatic and runs it
9. Installs MSYS2 and MINGW development toolchain for use in ruby's gems compilation
11. Install pass (by pacman) and symlinks to it

### 2. Second stage deploy script (in bash)

At this point, Git Bash should be installed by the first script. Start Git Bash as your regular user and run the following:

```sh
~/.runag/bin/runag
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
│           ├── config.linux
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

Please use [ShellCheck](https://www.shellcheck.net/). If it is not integrated into your editor, you could run `npm run lint`.

We mostly follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html).

Licensed under the [Apache License, Version 2.0](LICENSE).

Inspired by practices of [the Linux Foundation](https://www.linuxfoundation.org/) we use [Developer Certificate of Origin](https://developercertificate.org/) to help us track contributions. 

If you can certify the below:

Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.

then please add a line saying:

Signed-off-by: Your Name <your_email@example.org>

to each of your commit messages using your real name. You could use `git commit -s` to help you with that.

In some cases, we may agree that you use a pseudonym for a contributions. You will be required to provide us with your real name using private channels with the agreement that we will make your real name public after some time. Upon our agreement, this can be a significant period, for example, 10 years after the initial contribution, maybe more. The use of pseudonyms for the contributions must not be a means to hide unauthorized use of intellectual property or to circumvent contractual obligations. We may accept contributions under the pseudonyms if the author has reason to be concerned for their safety or feels restricted in their freedom of expression as a result of societal pressure.

We want as much of the project as possible to be self-contained in the form of a collection of source code and data. Keeping the private list of contributors requires some ongoing effort of people or organizations, that is such a resource that we do not always have in sufficient quantity. However, we understand that sometimes this may be necessary and will try to help you.
