# Install

English (US)
Location: Russia

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

* set timezone automatically
* low touchpad sens
* keyboard repeat delay

# Language options

* For Russian set "Enforce strict ё"

# Onedrive

* Disable backup of desktop, documents, and pictures

# Razer

* Chrome connect, studio, and visualizer
  
# Chocolatey

```
choco feature enable -n allowGlobalConfirmation
choco install %USERPROFILE%\.sopka\lib\windows\packages.config --yes
choco upgrade all
```

# Manuall install

* MSI Dragon Center, audio driver, Nahimic
* NVIDIA
* Razer Synapse
* Telegram from the Microsoft Store
* Battle.net
* VMware
* Ruby using RubyInstaller

# Synchting

1. Download Synchting to some folder
2. https://docs.syncthing.net/users/autostart.html#windows
3. Add syncthing.exe to windows firewall

## Fullscreen optimizations

> https://devblogs.microsoft.com/directx/demystifying-full-screen-optimizations/

It is ok to have it on a decent machine, do not disable it.

## VMware

* Disable windows firewall for host-only network (VMnet1, check virtual network manager)
