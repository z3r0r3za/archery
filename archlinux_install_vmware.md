# Archlinux VMWare Install

## Start
Ensure keyboard layout is correct and test internet connection. Check available hard drives.
```shell
loadkeys us
ping -c 3 archlinux.org
lsblk
```

## PARTITION DISK
Create UEFI, root and home partitions. Change drive, sizes, partitions, as needed.
```shell
parted /dev/sda --script \
  mklabel gpt \
  mkpart ESP fat32 1MiB 954MiB \
  set 1 esp on \
  mkpart primary ext4 954MiB 105513MiB \
  mkpart primary ext4 105513MiB 100%
```

## FORMAT Partitions
Format filesystems and partitions as needed.
```shell
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3
```

## MOUNT
Mount partitions as needed.
```shell
mount /dev/sda2 /mnt
mkdir /mnt/{boot,home}
mount /dev/sda1 /mnt/boot
mount /dev/sda3 /mnt/home
```

## Install BASE SYSTEM
```shell
pacstrap -K /mnt base linux linux-headers linux-lts linux-lts-headers linux-firmware base-devel vim
```

## Generate FSTAB
```shell
genfstab -U /mnt >> /mnt/etc/fstab
```

## CHROOT Into System
```shell
arch-chroot /mnt
```

## Setup and generate Locale and Hostname
Example: `ln -sf /usr/share/zoneinfo/Region/City /etc/localtime`
```shell
ln -sf /usr/share/zoneinfo/America/Rainy_River /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "ENTER_HOST_NAME" > /etc/hostname
```

## Setup hosts file
```shell
cat <<EOF > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    ENTER_HOST_NAME.localdomain ENTER_HOST_NAME
EOF
```

## initial ramdisk environments and Root Password
```shell
mkinitcpio -P
passwd
```

## Setup BOOTLOADER Config
`systemd-boot` as the boot manager for UEFI. Change partition as needed.
```shell
bootctl install
cat <<EOT > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value /dev/sda2) rw
EOT
```

## install i3wm and other PACKAGES
```shell
pacman -S networkmanager pipewire pipewire-pulse pipewire-alsa sudo fastfetch \
  thunar terminator mousepad firefox zram-generator xorg-server xorg-xinit mesa \
  i3-wm i3status i3lock conky lightdm lightdm-slick-greeter dmenu rofi git
```

## Enable NetworkManager
```shell
systemctl enable NetworkManager
```

## Setup Config and Enable Lightdm
```shell
sed -i 's/^#greeter-session=.*/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf
systemctl enable lightdm
```

## VmWare Tools
Install if using vmware
```shell
pacman -S open-vm-tools
```

## For Nvidia
Ignore nvidia if you need something else or installing in a VM, which uses `mesa`.
```shell
pacman -S nvidia nvidia-utils nvidia-settings
```

## Setup USER
```shell
useradd -m -G wheel -s /bin/bash USERNAME
echo "Set user password:"
passwd USERNAME
```
Uncomment this line: `%wheel ALL=(ALL:ALL) ALL`
```shell
EDITOR=vim visudo
```
Save and exit vim: `Shift+:` - `wq` - `Enter` 
## ZRAM CONFIG  Config
```shell
cat <<EOT > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram/2
compression-algorithm = zstd
swap-priority = 100
EOT
```

## EXIT & REBOOT
```shell
exit
umount -R /mnt
reboot
```
Log in with the created user.
## After Reboot
**Note:** If you see "Error: status_command process exited unexpectedly (exit 1)" in the i3bar, make sure the locale is set from previous steps and run `sudo locale-gen` if needed.
Then restart i3wm: `Mod+Shift+r`

## Set up and Check zram
If there's a problem check config that was set previously.
```shell
systemctl daemon-reexec
systemctl start /dev/zram0
swapon --show
```

## Install other packages
```shell
sudo pacman -S picom nitrogen numlockx dunst guake flameshot feh unzip \
  unarchiver p7zip xorg-xclock filezilla adapta-gtk-theme materia-gtk-theme \
  conky-manager2 thunar-archive-plugin thunar-media-tags-plugin thunar-shares-plugin
```

## Change resolution if Needed
Use `xrandr` to see available resolutions.
```shell
xrandr
xrandr --output Virtual1 --mode 1920x1080
```
