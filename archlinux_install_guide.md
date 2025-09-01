# Archlinux VMWare Install

## Start
Ensure keyboard layout is correct and test internet connection. Check available hard drives.
```shell
loadkeys us
ping -c 3 archlinux.org
lsblk
```

## Partition Disk
Create GPT/EFI, root and home partitions. Change drive, sizes, partitions, as needed.
```shell
parted /dev/sda --script \
  mklabel gpt \
  mkpart ESP fat32 1MiB 954MiB \
  set 1 esp on \
  mkpart primary ext4 954MiB 105513MiB \
  mkpart primary ext4 105513MiB 100%
```
For legacy BIOS, create MBR with BIOS boot partition.
NOTE: GRUB will install directly to MBR (/dev/sda)
```shell
    parted /dev/sda --script \
      mklabel msdos \
      mkpart primary ext4 1MiB 30GiB \
      mkpart primary ext4 30GiB 100%
```

## Format Partitions
EFI partitions: Format filesystems and partitions as needed.
```shell
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3
```

## Mount
Mount partitions as needed.
```shell
mount /dev/sda2 /mnt
mkdir /mnt/{boot,home}
mount /dev/sda1 /mnt/boot
mount /dev/sda3 /mnt/home
```

## Install Base System
```shell
pacstrap -K /mnt base linux linux-headers linux-lts linux-lts-headers linux-firmware base-devel vim
```

## Generate fstab
```shell
genfstab -U /mnt >> /mnt/etc/fstab
```

## Chroot Into System
```shell
arch-chroot /mnt /usr/bin/bash
```

## Setup and Generate Locale and Hostname
Example: `ln -sf /usr/share/zoneinfo/Region/City /etc/localtime`
```shell
ln -sf /usr/share/zoneinfo/America/Rainy_River /etc/localtime
hwclock --systohc
```
Instead of the echo command below you could open `etc/locale.gen` 
and  uncomment the line: en_US.UTF-8 UTF-8
before you run `locale-gen`
```shell
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "ENTER_HOST_NAME" > /etc/hostname
```

## Setup Hosts File
```shell
cat <<EOF > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    ENTER_HOST_NAME.localdomain ENTER_HOST_NAME
EOF
```

## Initial Ramdisk Environments and Root Password
```shell
mkinitcpio -P
passwd
```

## Setup Bootloader Config
`systemd-boot` as the boot manager for UEFI. Change partition as needed.
```shell
bootctl install
mkdir -p /boot/loader
cat > /boot/loader/loader.conf <<EOF
default arch.conf
timeout 5
console-mode max
editor no
EOF
```

```shell
cat <<EOT > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value /dev/sda2) rw
EOT
```

```shell
cat > /boot/loader/entries/arch-lts.conf <<EOF
title   Arch Linux (LTS)
linux   /vmlinuz-linux-lts
initrd  /initramfs-linux-lts.img
options root=UUID=$(blkid -s UUID -o value /dev/sda2) rw
EOF
```

## Legacy BIOS
Use this is not UEFI
```shell
echo "Legacy BIOS system detected: installing GRUB."
pacman -S --noconfirm grub
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
```

## Install i3wm and Other Packages
```shell
pacman -S networkmanager pipewire pipewire-pulse pipewire-alsa sudo fastfetch xsel \
  thunar terminator mousepad firefox zram-generator xorg-server xorg-xinit mesa wget \
  pacman-contrib i3-wm i3status conky lightdm lightdm-slick-greeter dmenu rofi git \
  network-manager-applet picom nitrogen numlockx dunst guake gedit flameshot unzip \
  unarchiver p7zip xorg-xrandr xorg-xclock feh filezilla adapta-gtk-theme materia-gtk-theme \
  adw-gtk-theme deepin-gtk-theme conky-manager2 thunar-archive-plugin thunar-shares-plugin \
  thunar-media-tags-plugin
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

## VMware Tools
[VMware Install Arch Linux as guest](https://wiki.archlinux.org/title/VMware/Install_Arch_Linux_as_a_guest)
Install if using VMware
```shell
pacman -S open-vm-tools
```

## For Nvidia
Ignore nvidia if you need something else or installing in a VM, which uses `mesa`.
```shell
pacman -S nvidia nvidia-utils nvidia-settings
```

## Setup User
```shell
useradd -m -G wheel -s /bin/bash USERNAME
passwd USERNAME
```
Uncomment this line: `%wheel ALL=(ALL:ALL) ALL`
```shell
EDITOR=vim visudo
```
Save and exit vim: `Shift+:` - `wq` - `Enter` 
## Zram Config
```shell
cat <<EOT > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram/2
compression-algorithm = zstd
swap-priority = 100
EOT
```

## Exit & Reboot
```shell
exit
umount -R /mnt
reboot
```
Log in with the user you created.

## Set up and Check zram
If there's a problem check config that was set previously.
```shell
systemctl daemon-reexec
systemctl start /dev/zram0
swapon --show
```

## VMware Tools Enable
[VMware Install Arch Linux as guest](https://wiki.archlinux.org/title/VMware/Install_Arch_Linux_as_a_guest)
Enable if you are using VMWare
```shell
sudo systemctl enable vmtoolsd.service
sudo systemctl enable vmware-vmblock-fuse.service
``` 

## Share a folder with VMware
Edit virtual machine settings > Options > Shared Folders > Always enabled, and create a new share.
The shared folders should be visible with: `vmware-hgfsclient`
```
mkdir /home/USER/share
vmhgfs-fuse -o allow_other -o auto_unmount .host:/SHARE_NAME SHARE_DIRECTORY
```

## Change Resolution
Use `xrandr` to see available resolutions.
```shell
xrandr
xrandr --output Virtual-1 --mode 1600x900
xrandr --output Virtual-1 --mode 1920x1080
```