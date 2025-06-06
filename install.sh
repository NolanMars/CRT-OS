#!/bin/bash

#############
# Variables #
#############
LANGAGE=fr
HOSTNAME="CRT-OS"
USERNAME=guybrush
USERPASSWORD=changeme
ROOTPASSWORD=changeme

########
# LOGO #
########
clear
cat << "EOF"
 
 ██████╗██████╗ ████████╗     ██████╗ ███████╗
██╔════╝██╔══██╗╚══██╔══╝    ██╔═══██╗██╔════╝
██║     ██████╔╝   ██║       ██║   ██║███████╗
██║     ██╔══██╗   ██║       ██║   ██║╚════██║
╚██████╗██║  ██║   ██║       ╚██████╔╝███████║
 ╚═════╝╚═╝  ╚═╝   ╚═╝        ╚═════╝ ╚══════╝
                                              

EOF

#
# Initialisation password ROOT
#
echo $ROOTPASSWORD | passwd root --stdin

#
# Language clavier
#
loadkeys $LANGAGE

#
# Detection boot bios/UEFI
#
bootmode=$(cat /sys/firmware/efi/fw_platform_size)

echo "$bootmode"

if [ "$bootmode" = "64" ] || [ "$bootmode" = "32" ]
then
echo "uefi"
else
echo "ko"

read -s -n 1

#
#  Initialisation du disque
#
lsblk -e7

echo ""

echo "Sur quel disque installer CRT OS ?"

read disque

wipefs -a -f /dev/$disque

if [ "$bootmode" = "64" ] || [ "$bootmode" = "32" ]
then
echo "ok"
else
echo "ko"
fi
read -s -n 1

sfdisk /dev/$disque << EOF
label: gpt
,1G,U
;
write
EOF

mkfs.vfat /dev/"$disque"1
mkfs.ext4 /dev/"$disque"2
else

read -s -n 1

# Chroot into new system
arch-chroot /mnt /bin/bash <<EOF
#
# Set timezone.
# Default to America/Los_Angeles, change to your preferred timezone if needed.
#
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
hwclock --systohc

#
# Set locale
# Default to en_US.UTF-8, change to your preferred locale if needed.
#
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo $HOSTNAME > /etc/hostname
# Create User
useradd -m -G wheel --shell /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
# Allow wheel group to use sudo
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

#
# Configure mkinitcpio
#
pacman -S --noconfirm lvm2
# 
# - block, keyboard is kept before autodetect for possible multi-system.
# - encrypt, lvm is added before filesystems.
#
sed -i 's/^HOOKS=(.*)/HOOKS=(base udev block keyboard autodetect microcode modconf kms keymap consolefont encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P
# Install bootloader
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
# Generate grub config
sed -r 's%^GRUB_CMDLINE_LINUX=""%GRUB_CMDLINE_LINUX="cryptdevice=UUID=$ROOT_DISK_UUID:cryptlvm root=/dev/vg0/root"%' -i /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
# Install network manager
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager
# Exit and unmount
exit
EOF
# Unmount partitions
umount -R /mnt
swapoff /dev/vg0/swap
