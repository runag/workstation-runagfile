# Install

## How to choose ubuntu version
Install only LTS release as its most stable


## Partition

* Ensure all partitions for 4k alignment
> https://www.intel.com/content/dam/www/public/us/en/documents/technology-briefs/ssd-partition-alignment-tech-brief.pdf

1) (IF MAC) MacOS partition app

    * Make half the drive as APFS
    * Make 600 mb partition for /boot (format as hfs for now)
    * Make the rest as one partition (format as hfs for now)

2) Ubuntu installer

    * Format first, /boot, ext4 journalling, 600 MB
    * Second use as encrypted
    * Make / inside encrypted
    * Install boot loader on /boot partition, not to the /sda (tho whole drive)


## EFI and windows dual boot
Use efibootmgr tool after ubuntu is installed to put windows first in boot order,
otherwise the bitlocker will ask for key at every boot)

```sh
sudo efibootmgr
sudo efibootmgr --bootorder xxxx
```

```sh
echo 'alias reboot-me="sudo efibootmgr --bootnext 0002 && sudo reboot"' | sudo tee /etc/profile.d/reboot-me.sh
```


# Hardware

## Macbook Air mid-2012

### Drivers for "Broadcom BCM4353" (Macbook air 2012)

> https://askubuntu.com/a/978626

On 18.04 default driver somehow works but connection in unreliable.

On 19.? you need USB network dongle first

Do not use proprietary drivers at install-time

On 18.04 just enable proprietary drivers from the interface.

On 19.? do the following:

```sh
sudo apt-get install ubuntu-sta-common ubuntu-sta-source ubuntu-sta-dkms
```


### Macbook video driver fix
drm:drm_atomic_helper_wait_for_flip_done flip_done timed out

> from https://askubuntu.com/questions/893817/boot-very-slow-because-of-drm-kms-helper-errors
> from https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1685442

```sh
sudo nano /etc/default/grub

# edit
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash video=SVIDEO-1:d"

sudo update-grub
sudo reboot
```


### Scrolling on Mac

> based on https://www.reddit.com/r/linux/comments/72mfv8/psa_for_firefox_users_set_moz_use_xinput21_to/

1. Make the following file:

```sh
echo export MOZ_USE_XINPUT2=1 | sudo tee /etc/profile.d/moz_use_xinput2.sh
```

2. Log out, log in

3. Disable smooth scrolling in firefox preferences

### Macbook fan control
```sh
sudo apt install mbpfan
sudo nano /etc/mbpfan.conf
# edit:
# polling interval 4

sudo systemctl restart mbpfan.service

sudo systemctl enable mbpfan.service
sudo systemctl daemon-reload
sudo systemctl start mbpfan.service

sudo apt install psensor
# configure to show TC0C in notification area
```


## NVIDIA

### Open source driver for NVIDIA + WAYLAND on Ubuntu 18.04 LTS
* Terrible input lag (mouse feel terrible)
* Lag when moving window from one monitor to another

Just use nvidia proprietary driver + xorg


### My desktop NVIDIA 1060 card
Install nvidia driver bacause nouvae can't controll the FAN


## My encrypted disks
```sh
export BW_SESSION="$(bw unlock --raw)"

bw get password "yaphit disk key" | tr -d '\n' | (umask 277; sudo tee /etc/yaphit.key >/dev/null)

echo "yaphit UUID=6e1c941a-badc-4bd5-849b-e20296cca819 /etc/yaphit.key luks,discard" | sudo tee -a /etc/crypttab

sudo cryptdisks_start yaphit

mkdir /home/stan/yaphit

echo "/dev/disk/by-uuid/9b900fbd-1435-4582-b3b0-e19f33782bb0 /home/stan/yaphit auto nosuid,nodev,nofail,x-gvfs-show 0 0" | sudo tee -a /etc/fstab

sudo mount -a
```


## Web camera
https://help.ubuntu.com/community/Webcam/Troubleshooting

```sh
guvcview
```


# System configuration

## Swap
```sh
test -f /swapfile && sudo swapoff /swapfile
sudo dd if=/dev/zero of=/swapfile bs=1M count=4096
sudo chmod 0600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

sudo nano /etc/fstab
# make sure /etc/fstab contains
/swapfile  none  swap  sw  0  0
```


## Grub
```sh
sudo nano /etc/default/grub
# change the following:
# GRUB_TIMEOUT=1
sudo update-grub
```


# Applications

## Bitwarden
```sh
export BW_SESSION="$(bw login stan@senotrusov.com --raw)"
export BW_SESSION="$(bw unlock --raw)"
bw sync
```


## TOR
```sh
# https://2019.www.torproject.org/docs/debian.html.en

sudo nano /etc/tor/torrc

# add the following
HiddenServiceDir /var/lib/tor/ssh_hidden_service/
HiddenServiceVersion 3
HiddenServicePort 22 127.0.0.1:22

sudo systemctl restart tor

sudo cat /var/lib/tor/ssh_hidden_service/hostname

journalctl -f --since today
```


## GPG
```sh
gpg --import stan-at-senotrusov-com-gpg-key.txt
gpg --edit-key stan@senotrusov.com trust
```


## KVM
> https://help.ubuntu.com/community/KVM/Installation

```sh
sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
# reboot the computer and see if you are in libvirt group
groups
```


## lstopo
```sh
# Show the system topology
lstopo
lstopo-no-graphics
```

## Firefox
mousewheel.default.delta_multiplier_x 200
mousewheel.default.delta_multiplier_y 200
general.smoothScroll false
