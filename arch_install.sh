#!/usr/bin/env bash

# ===================================================================
# Arch Linux Installation Script
# ===================================================================
# This script installs Arch Linux with basic i3 desktop environment, 
# i3WM, xorg, systemd, themes, and configs.
# Author: z3r0r3za
# URL: https://github.com/z3r0r3za/archery
# Version: 1.0 Alpha
# ===================================================================

exec > >(tee $HOME/arch_install.log) 2>&1

cat <<EOF

#####################################################################
##                   Arch Linux Installation                       ##
#####################################################################

This script will install Arch Linux. Some of the settings need to be 
modified before you use this script such as credentials, disk name 
and sizes of partitions. I might create some options to handle that 
at some point. It checks for Nvidia and will install drivers.

It does check for UEFI or Legacy BIOS, but you should enable UEFI 
on virtualbox or vmware before installing or it won't boot after.

NOTE: tested only on virtualbox but should be working on vmware and 
bare metal. The password and username used below are just temporoary 
for the installation. You can change them before using this file or 
when it's done after rebooting into the new system.

Setup starts or stops when key is pressed (1 or q):

  [1] Install everything now
  [q] Quit without installing

EOF

while true; do
    read -n1 -p "Enter option [1] or press q to exit: " choice
    case "$choice" in
        1) echo -e "\nStart installation now"; break ;;
        [Qq]) echo -e "\nExiting..."; exit 0 ;;
        *) echo -e "\nInvalid input. Please enter 1 or q to exit.\n" ;;
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

# Partition disk for either UEFI or Grub
if [ -d /sys/firmware/efi ]; then
    echo "UEFI detected: creating GPT with EFI System Partition"
    parted /dev/sda --script \
      mklabel gpt \
      mkpart ESP fat32 1MiB 954MiB \
      set 1 esp on \
      mkpart primary ext4 954MiB 30GiB \
      mkpart primary ext4 30GiB 100%
else
    echo "Legacy BIOS detected: creating MBR with BIOS boot partition"
    parted /dev/sda --script \
      mklabel msdos \
      mkpart primary ext4 1MiB 30GiB \
      mkpart primary ext4 30GiB 100%
    # NOTE: GRUB will install directly to MBR (/dev/sda)
fi

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
arch-chroot /mnt /usr/bin/bash <<CHROOT_EOF
set -euo pipefail

NEW_USER="zerorez"
TEMP_ROOT_PASSWORD="4rc#71NUx"

# Locale, time, and hostname.
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "zerorez" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1    localhost
::1          localhost
127.0.1.1    zerorez.localdomain zerorez
EOF

# Initramfs
mkinitcpio -P

# Systemd-boot setup for UEFI or for Legacy BIOS and Grub.
if [ -d /sys/firmware/efi ]; then
    echo "UEFI system detected: installing systemd-boot."
    bootctl install
    mkdir -p /boot/loader
    cat > /boot/loader/loader.conf <<EOF
default arch.conf
timeout 5
console-mode max
editor no
EOF
    
    cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value /dev/sda2) rw
EOF

    cat > /boot/loader/entries/arch-lts.conf <<EOF
title   Arch Linux (LTS)
linux   /vmlinuz-linux-lts
initrd  /initramfs-linux-lts.img
options root=UUID=$(blkid -s UUID -o value /dev/sda2) rw
EOF

else
    echo "Legacy BIOS system detected: installing GRUB."
    pacman -S --noconfirm grub

    grub-install --target=i386-pc /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# Install core packages to get started.
pacman -S --noconfirm networkmanager pipewire pipewire-pulse pipewire-alsa sudo fastfetch xsel \
  thunar terminator mousepad firefox zram-generator xorg-server xorg-xinit mesa wget \
  pacman-contrib i3-wm i3status conky lightdm lightdm-slick-greeter dmenu rofi git \
  network-manager-applet picom nitrogen numlockx dunst guake gedit flameshot unzip xorg-xrandr \
  unarchiver p7zip xorg-xclock feh filezilla adapta-gtk-theme materia-gtk-theme \
  adw-gtk-theme deepin-gtk-theme conky-manager2 thunar-archive-plugin thunar-shares-plugin \
  thunar-media-tags-plugin

# Install Nvidia if detected.
if lspci -k | grep -i "nvidia" &> /dev/null; then
    pacman -S nvidia nvidia-utils nvidia-settings
fi

# Install VMware tools if needed.
if [[ "$5" == "VMWARE" ]]; then
    pacman -S open-vm-tools
fi

# Enable networkmanager and lightdm.
systemctl enable NetworkManager

if pacman -Qi lightdm-slick-greeter &>/dev/null; then
    sed -i 's/^#greeter-session=.*/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf
else
    sed -i 's/^#greeter-session=.*/greeter-session=lightdm-gtk-greeter/' /etc/lightdm/lightdm.conf
fi

systemctl enable lightdm

# Append theme to environment.
if ! grep -q 'GTK_THEME="adw-gtk3-dark"' /etc/environment; then
    echo 'GTK_THEME="adw-gtk3-dark"' >> /etc/environment
fi

# Root/user setup
echo "root:4rc#71NUx" | chpasswd --crypt-method=SHA512

grep -q '^wheel:' /etc/group || groupadd wheel

if ! id "zerorez" &>/dev/null; then
  useradd -m -G wheel -s /bin/bash zerorez
fi
echo "zerorez:4rc#71NUx" | chpasswd --crypt-method=SHA512

cat > "/etc/sudoers.d/zerorez" <<EOF
zerorez ALL=(ALL:ALL) ALL
EOF
visudo -c -f "/etc/sudoers.d/zerorez"

sed -i '/%wheel ALL=(ALL:ALL) ALL/s/^#\s*//' /etc/sudoers

# Save the passwords so you can read them after reboot
printf "root: %s\n%s: %s\n" "4rc#71NUx" "zerorez" "4rc#71NUx" > /root/INSTALL_PASSWORDS.txt
chmod 600 /root/INSTALL_PASSWORDS.txt

# zram config (activation happens after reboot)
cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = ram/2
compression-algorithm = zstd
swap-priority = 100
EOF

CHROOT_EOF

# Exit arch-chroot and reboot.
umount -R /mnt
echo "After reboot, run:"
echo "  sudo systemctl daemon-reexec"
echo "  sudo systemctl start /dev/zram0"
echo "  swapon --show"
