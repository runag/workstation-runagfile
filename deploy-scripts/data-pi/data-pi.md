## a) Raspbian

> https://www.raspberrypi.org/documentation/installation/installing-images/linux.md

```sh
lsblk
dd bs=4M if=2018-11-13-raspbian-stretch.img of=/dev/sdX conv=fsync status=progress
```

## b) Ubuntu

> https://wiki.ubuntu.com/ARM/RaspberryPi

```sh
xzcat ubuntu-18.04.2-preinstalled-server-armhf+raspi2.img.xz | sudo dd of=/dev/sdc bs=32M conv=fsync status=progress
```


# Add public SSH key


# Format external hdd

```sh
lsblk
fdisk /dev/sda
sudo cryptsetup --verbose --verify-passphrase luksFormat /dev/sda1
sudo cryptsetup luksOpen /dev/sda1 kelly
sudo mkfs.ext4 /dev/mapper/kelly
mkdir $HOME/kelly
sudo mount /dev/mapper/kelly $HOME/kelly
```


# Install syncthing

```sh
# this string will run syncthing with its output to a terminal
syncthing -no-browser -home="/home/ubuntu/kelly/.config/stan-data-pi.syncthing"

# print the paths used for configuration, keys, database, GUI overrides, default sync folder and the log file.
syncthing -home="/home/ubuntu/kelly/.config/stan-data-pi.syncthing" -paths

sudo install --mode="0644" --owner="root" --group="root" "/home/ubuntu/kelly/.config/syncthing-kelly@.service" -D "/lib/systemd/system"

systemctl enable syncthing-kelly@ubuntu.service
systemctl start syncthing-kelly@ubuntu.service
```


# Install backup-data-pi config


# Access the backup shell

```sh
data-pi
backup-data-pi shell
borg list
```


# Make sure no swap is on the flash cause it's not secure and wears off flash

swapFile="${HOME}/kelly/swapfile"
test -f "${swapFile}" && sudo swapoff "${swapFile}"
sudo dd if=/dev/zero of="${swapFile}" bs=1M count=2048 status=progress
sudo chmod 0600 "${swapFile}"
sudo mkswap "${swapFile}"
sudo swapon "${swapFile}"
