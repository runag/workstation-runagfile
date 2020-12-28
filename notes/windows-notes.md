
# May be useful later

## Change network category

```
Get-NetConnectionProfile
Set-NetConnectionProfile -Name "FOOBAR" -NetworkCategory Private
```

## Check Wi-Fi speed

```
netsh wlan show interfaces
```

## Disable/Enable Hyper-V

In admin console:

```
bcdedit /set hypervisorlaunchtype off
bcdedit /set hypervisorlaunchtype auto
```

## Shrink partition

> https://superuser.com/questions/1017764/how-can-i-shrink-a-windows-10-partition
> https://superuser.com/a/1175556

```
Optimize-Volume -DriveLetter C -ReTrim -Defrag -SlabConsolidate -TierOptimize -NormalPriority
Resize-Partition -DriveLetter C -Size 300GB
```

## VMware

PSCSI-NVME is the best performing disk configuration

For each VM: Options -> Guest Isolation -> Disable Drag & Drop (VM UI randomly hangs because of that).

## Wake timers (Virtualbox wakes host from sleep)

Power Options -> Advanced Settings -> Sleep -> Allow wake timers
