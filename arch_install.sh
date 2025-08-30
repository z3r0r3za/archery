#!/usr/bin/env bash

# ========================================
# Arch Linux Installation Script
# ========================================
# This script installs Arch Linux with basic desktop environment, 
# i3WM, xorg, systemd, themes, and configs.
# Author: z3r0r3za
# URL: https://github.com/z3r0r3za/archery
# Version: 1.0
# ========================================

cat <<EOF

###########################################################################
##                      Arch Linux Installation                          ##
###########################################################################

This script will install Arch Linux. You will need to:
- Enter your sudo password
- Edit file in vim 
- Confirm some choices during setup

Some of the setting need to be changed depending on the situation and 
what you want.

NOTE: still in progress and testing.

Setup starts or stops when key is pressed (1 or q):

  [1] Install everything now
  [q] Quit without installing

EOF

while true; do
    read -n1 -p "Enter option [1] or press q to exit: " choice
    case "$choice" in
        1) echo -e "/nStart installation now"; break ;;
        [Qq]) echo -e "\nExiting..."; exit 0 ;;
        *) echo -e "/nInvalid input. Please enter 1 or q to exit.\n" ;;
    esac
done

# Initialize and ping for connection.
loadkeys us
loadkeys us || { echo "Failed to load US keyboard layout."; exit 1; }
echo -e "\n Testing internet connection with ping..."
if ! ping -c 3 archlinux.org &> /dev/null; then
    echo -e "\n No internet connection detected. Cannot proceed.\n"
    echo "Please connect to the internet and try again."
    exit 1
fi
echo -e "Online and ready to proceed...\n"

if [ ! -e /dev/sda ]; then
    echo -e "\nDevice /dev/sda not found. Please verify your disk.\n"
    exit 1
fi

# Partition disk
parted /dev/sda --script \
  mklabel gpt \
  mkpart ESP fat32 1MiB 954MiB \
  set 1 esp on \
  mkpart primary ext4 954MiB 30513MiB \
  mkpart primary ext4 30513MiB 100%

# Format partitions.
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3

# Mount partitions.
mount /dev/sda2 /mnt
mkdir /mnt/{boot,home}
mount /dev/sda1 /mnt/boot
mount /dev/sda3 /mnt/home

# Install base system.
pacstrap -K /mnt base linux linux-headers linux-lts linux-lts-headers linux-firmware base-devel vim

# Generate fstab.
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into mounted system.
arch-chroot /mnt <<'CHROOT_EOF'
## Setup and generate locale and hostname.
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "zerorez" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    zerorez.localdomain zerorez
EOF

# Initial ramdisk environments and root password.
mkinitcpio -P
echo -e "Create a password for root user."
passwd

# Setup bootloader config.
bootctl install
cat <<EOT > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value /dev/sda2) rw
EOT

# Install i3wm and other packages.
pacman -S networkmanager pipewire pipewire-pulse pipewire-alsa sudo fastfetch xset \
  thunar terminator mousepad firefox zram-generator xorg-server xorg-xinit mesa wget \
  pacman-contrib i3-wm i3status conky lightdm lightdm-slick-greeter dmenu rofi git \
  network-manager-applet

# Enable NetworkManager.
systemctl enable NetworkManager

## Enable lightdm  and setup config.
sed -i 's/^#greeter-session=.*/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf
systemctl enable lightdm

# Install VMware tools if needed.
# pacman -S open-vm-tools

# Install Nvidia if needed.
# pacman -S nvidia nvidia-utils nvidia-settings

# Setup new user.
useradd -m -G wheel -s /bin/bash zerorez
echo -e "Enter password for new user."
passwd zerorez
echo -s "Uncomment this line and save file: %wheel ALL=(ALL:ALL) ALL"
EDITOR=vim visudo

# zrzm config.
cat <<EOT > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram/2
compression-algorithm = zstd
swap-priority = 100
EOT

# Install more packages before rboot.
sudo pacman -S picom nitrogen numlockx dunst guake gedit flameshot unzip xorg-xrandr \
  unarchiver p7zip xorg-xclock feh filezilla adapta-gtk-theme materia-gtk-theme \
  adw-gtk-theme deepin-gtk-theme conky-manager2 thunar-archive-plugin thunar-shares-plugin \
  thunar-media-tags-plugin
CHROOT_EOF

# Exit and reboot.
exit
umount -R /mnt
echo -e "After rebooting you need to run:"
echo "systemctl daemon-reexec"
echo "systemctl start /dev/zram0"
echo "swapon --show"
echo -e "All done! type reboot and hit enter."
#reboot
