# NVIDIA + WAYLAND on Ubuntu 18.04 LTS
* Terrible input lag (mouse feel terrible)
* Lag when moving window from one monitor to another

Just use nvidia proprietary driver + xorg

# Laptop screen tearing
> from https://www.reddit.com/r/linuxquestions/comments/8fb9oj/how_to_fix_screen_tearing_ubuntu_1804_nvidia_390/

```sh
sudo nano /etc/modprobe.d/zz-nvidia-modeset.conf

# add
options nvidia_drm modeset=1

sudo update-initramfs -u
```

# My desktop NVIDIA 1060 card
Install nvidia driver bacause nouvae can't controll the FAN


# How to choose ubuntu version
Install only LTS release as its most stable (all other releases are shaky)


# Partition
1) (IF MAC) MacOS partition app

    * Make half the edrive as APFS
    * Make 600 mb partition for /boot (format as hfs for now)
    * Make the rest as one partition (format as hfs for now)

2) Ubuntu installer

    * Format first, /boot, ext4 journalling, 600 MB
    * Second use as encrypted
    * Make / inside encrypted
    * Install boot loader on /boot partition, not to the /sda (tho whole drive)


# EFI and windows dual boot
Use efibootmgr tool after ubuntu is installed to put windows first in boot order,
otherwise the bitlocker will ask for key at every boot)


```sh
sudo efibootmgr
sudo efibootmgr --bootorder xxxx
```

```sh
echo 'alias reboot-me="sudo efibootmgr --bootnext 0002 && sudo reboot"' | sudo tee /etc/profile.d/reboot-me.sh
```


# Drivers for "Broadcom BCM4353" (Macbook air 2012)
You will need USB wifi first

Do not use proprietary drivers at install-time

sudo apt-get install ubuntu-sta-common ubuntu-sta-source ubuntu-sta-dkms


# Macbook video driver fix
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


# Scrolling on Mac
> from https://www.reddit.com/r/linux/comments/72mfv8/psa_for_firefox_users_set_moz_use_xinput21_to/
> Run this command: echo export MOZ_USE_XINPUT2=1 | sudo tee /etc/profile.d/use-xinput2.sh
> Log out and back in.
> Firefox should now use xinput 2.
> (optional) Open Firefox and go to about:preferences -> Advanced (or about:preferences -> Browsing for Firefox Nightly), and uncheck Use smooth scrolling. This disables the old style smooth scrolling, which just causes an annoying delay when using xinput2 style scrolling imo.


# Macbook fan control
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

# Bitwarden
```sh
export BW_SESSION="$(bw login stan@senotrusov.com --raw)"
export BW_SESSION="$(bw unlock --raw)"
bw sync
```

# Swap
```sh
sudo swapoff /swapfile
sudo dd if=/dev/zero of=/swapfile bs=4M count=1024 oflag=append conv=notrunc
sudo mkswap /swapfile
sudo swapon /swapfile
```

# KVM VM
> https://help.ubuntu.com/community/KVM/Installation

```sh
sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
# reboot the computer and see if you are in libvirt group
groups
```


# GPG
```sh
gpg --import stan-at-senotrusov-com-gpg-key.txt
gpg --edit-key stan@senotrusov.com trust
```

# Grub
```sh
sudo nano /etc/defaults/grub
# change the following:
# GRUB_TIMEOUT=1
sudo update-grub
```

# My encrypted disks
```sh
export BW_SESSION="$(bw unlock --raw)"

bw get password "bortus disk key" | tr -d '\n' | (umask 277; sudo tee /etc/bortus.key >/dev/null)
bw get password "yaphit disk key" | tr -d '\n' | (umask 277; sudo tee /etc/yaphit.key >/dev/null)

echo "bortus UUID=053d8f94-7026-461c-9ca4-3af81c71290e /etc/bortus.key luks,discard" | sudo tee -a /etc/crypttab
echo "yaphit UUID=6e1c941a-badc-4bd5-849b-e20296cca819 /etc/yaphit.key luks,discard" | sudo tee -a /etc/crypttab

sudo cryptdisks_start bortus
sudo cryptdisks_start yaphit

mkdir /home/stan/bortus
mkdir /home/stan/yaphit

echo "/dev/disk/by-uuid/51328ad9-023e-4d5b-8000-259a2fb9a042 /home/stan/bortus auto nosuid,nodev,nofail,x-gvfs-show 0 0" | sudo tee -a /etc/fstab
echo "/dev/disk/by-uuid/9b900fbd-1435-4582-b3b0-e19f33782bb0 /home/stan/yaphit auto nosuid,nodev,nofail,x-gvfs-show 0 0" | sudo tee -a /etc/fstab

sudo mount -a
```

# Dropbox
```sh
sudo apt install python3-gpg
```

# Desktop mouse
> from https://askubuntu.com/questions/1067062/change-mouse-speed-on-ubuntu-18-04

```sh
xinput --list-props 'ASUS ROG SICA' | grep 'libinput Accel Speed ('
xinput --set-prop 'ASUS ROG SICA' 'libinput Accel Speed' -0.7

for (( ; ; )); do xinput --list-props 'ASUS ROG SICA' | grep 'libinput Accel Speed ('; done
# get it close to -0.7
# -0.699640
```

# pgadmin4
> from https://askubuntu.com/questions/831262/how-to-install-pgadmin-4-in-desktop-mode-on-ubuntu

```sh
sudo apt-get install virtualenv python3-pip libpq-dev python3-dev

cd ~
virtualenv -p python3 .pgadmin4
cd .pgadmin4
source bin/activate

# get the latest version URL https://www.postgresql.org/ftp/pgadmin/pgadmin4/
pip3 install https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v4.10/pip/pgadmin4-4.10-py2.py3-none-any.whl

cat <<PYTHON | tee ~/.pgadmin4/lib/python3.6/site-packages/pgadmin4/config_local.py
import os

DATA_DIR = os.path.realpath(os.path.expanduser(u'~/.pgadmin/'))

LOG_FILE = os.path.join(DATA_DIR, 'pgadmin4.log')
SQLITE_PATH = os.path.join(DATA_DIR, 'pgadmin4.db')
SESSION_DB_PATH = os.path.join(DATA_DIR, 'sessions')
STORAGE_DIR = os.path.join(DATA_DIR, 'storage')

SERVER_MODE = False
MASTER_PASSWORD_REQUIRED=False
PYTHON

cat pgadmin4.service | sudo tee "/etc/systemd/system/pgadmin4.service"
sudo systemctl reenable "pgadmin4.service"
sudo systemctl start pgadmin4.service
```

* Navigate to http://localhost:5050

* Add server
  * localhost
  * /home/stan/.pgpass


# TOR
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


# Web cameras
https://help.ubuntu.com/community/Webcam/Troubleshooting

```sh
guvcview
```
