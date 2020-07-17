# Install

* English (US)
* Location: Russia

# Activation

* Check if "Windows is activated with a digital licence linked to your Microsoft account"

# Bitlocker

* run ``gpedit.msc``
* Local Computer Policy > Computer Configuration > Administrative Templates > Windows Components > BitLocker Drive Encryption > Operating System Drives
* Require additional authentication at startup
* Enabled
* Allow BitLocker without a compatible TPM (requires a password or a startup key on a USB flash drive)

# Graphics (?)

Intel control panel
Power
Plugged in
Maximum performance

# Misc

* timezone: set automatically
* touchpad sensitivity: low

# Language options

* For Russian set "Enforce strict ё"

# Onedrive

* Disable backup of desktop, documents, and pictures

# Razer

* Synapse, chrome connect, studio, and visualizer
  
# Chocolatey

```
# open admin terminal
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
# reopen terminal
Invoke-WebRequest https://raw.githubusercontent.com/senotrusov/stan-computer-deploy/master/lib/windows/packages.config -OutFile $env:USERPROFILE/packages.config
choco feature enable -n allowGlobalConfirmation
choco install $env:USERPROFILE/packages.config --yes
choco upgrade all
```

# Manuall install

* MSI Dragon Center, audio driver, Nahimic
* NVIDIA driver?
* Telegram from the Microsoft Store
* Battle.net
* VMware
  * Disable windows firewall for host-only network (VMnet1, check virtual network manager)
* Ruby using RubyInstaller

# Synchting

1. Download Synchting to some folder
2. https://docs.syncthing.net/users/autostart.html#windows
3. Add syncthing.exe to windows firewall

# Fullscreen optimizations

> https://devblogs.microsoft.com/directx/demystifying-full-screen-optimizations/

It is ok to have it on a decent machine, do not disable it.
