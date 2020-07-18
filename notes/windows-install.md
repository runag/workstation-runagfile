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

# Misc

* timezone: set automatically
* touchpad sensitivity: low

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

# Manuall install

* MSI Dragon Center, audio driver, nahimic
* Battle.net
* VMware
  * Disable windows firewall for host-only network (VMnet1, check virtual network manager)
* Ruby using RubyInstaller (that one from choco can't install (compile) some gems, namely sqlite)
* NVIDIA driver (or leave the system one?)

# Synchting

1. Download Synchting to some folder
2. https://docs.syncthing.net/users/autostart.html#windows
3. Add syncthing.exe to windows firewall

# Graphics

## Fullscreen optimizations

> https://devblogs.microsoft.com/directx/demystifying-full-screen-optimizations/

* It is ok to have it on a decent machine, do not disable it.

## Microsoft overlays (keep them?)
