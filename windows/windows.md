# Disable/Enable Hyper-V

In admin console:

bcdedit /set hypervisorlaunchtype off
bcdedit /set hypervisorlaunchtype auto

# Windows update

1. Open advanced windows update options
2. switch to semi-annual channel

# Shrink partition

> https://superuser.com/questions/1017764/how-can-i-shrink-a-windows-10-partition
> https://superuser.com/a/1175556

Optimize-Volume -DriveLetter C -ReTrim -Defrag -SlabConsolidate -TierOptimize -NormalPriority
Resize-Partition -DriveLetter C -Size 300GB
