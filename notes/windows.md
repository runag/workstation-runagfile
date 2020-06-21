# Chocolatey

choco feature enable -n allowGlobalConfirmation
choco install %USERPROFILE%\.sopka\lib\windows\packages.config --yes
choco upgrade all

# Manuall install

* msi dragon center, audio driver
* nvidia
* razer synapse
* telegram from the ms store
* battle.net
* vmware
* ruby from rubyinstaller

# Synchting

1. download synchting to some folder
2. https://docs.syncthing.net/users/autostart.html#windows
3. add syncthing exe to windows firewall

# Configure

* low touchpad sens
* keyboard repeat delay

# Some notes

## Change network category

Get-NetConnectionProfile
Set-NetConnectionProfile -Name "FOOBAR" -NetworkCategory Private

## Check wifi speed

netsh wlan show interfaces

## Fullscreen optimizations

> https://devblogs.microsoft.com/directx/demystifying-full-screen-optimizations/

It is ok to have it on a decent machine, do not disable it.

## Disable/Enable Hyper-V

In admin console:

bcdedit /set hypervisorlaunchtype off
bcdedit /set hypervisorlaunchtype auto

## Shrink partition

> https://superuser.com/questions/1017764/how-can-i-shrink-a-windows-10-partition
> https://superuser.com/a/1175556

Optimize-Volume -DriveLetter C -ReTrim -Defrag -SlabConsolidate -TierOptimize -NormalPriority
Resize-Partition -DriveLetter C -Size 300GB

## VMware

PSCSI-NVME is the best performing disk configuration

Disable windows firewall for host-only network (VMnet1? Check virtual network manager)

## Wake timers

Power Options -> Advanced Settings -> Sleep -> Allow wake timers
