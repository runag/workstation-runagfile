# Install

* English (US)
* Location: Russia

# Activation

* Check if "Windows is activated with a digital licence linked to your Microsoft account"

# Bitlocker if I dont have TPM chip in my computer

* run ``gpedit.msc``
* Local Computer Policy > Computer Configuration > Administrative Templates > Windows Components > BitLocker Drive Encryption > Operating System Drives
* Require additional authentication at startup
* Enabled
* Allow BitLocker without a compatible TPM (requires a password or a startup key on a USB flash drive)
* Add "Add generic/text only" printer with the nul port. In powershell: ``add-printerport -Name nul``

# Misc

* timezone: set automatically
* touchpad sensitivity: low
* mouse speed: 5 at 3200dpi

# Language options

* For Russian set "Enforce strict ё"

# Onedrive

* Disable backup of desktop, documents, and pictures

# Razer

* Install synapse, chrome connect, studio, and visualizer

# Configure power options (or leave default?)

Intel control panel
Power
Plugged in
Maximum performance

# Drivers for my MSI laptop

* MSI Dragon Center
  * In each profile, remove shortcut
* Audio driver, nahimic

# Manual install

* Battle.net
* VMware
  * Disable windows firewall for host-only network (VMnet1, check virtual network manager)
* Ruby using RubyInstaller (that one from choco can't install (compile) some gems, namely sqlite)
* NVIDIA driver
* NVIDIA RTX Voice

# Synchting

1. Download Synchting to some folder
2. https://docs.syncthing.net/users/autostart.html#windows
3. Add syncthing.exe to windows firewall

# Graphics

## Fullscreen optimizations

> https://devblogs.microsoft.com/directx/demystifying-full-screen-optimizations/

* It is ok to have it on a decent machine, do not disable it.

`lib/windows/disable fullscreen optimizations.reg`

## Microsoft overlays (keep them?)

# Disable Sharing Wizard

File explorer options -> View
Uncheck "Use Sharing Wizard"
