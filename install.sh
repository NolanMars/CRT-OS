#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

#############
# Variables #
#############
VERSION="1.0"
LANGAGE=fr
HOSTNAME="CRT-OS"
USERNAME=guybrush
USERPASSWORD=changeme
ROOTPASSWORD=changeme

#####################
# Variables systeme #
#####################
CPUVENDOR=$(lscpu | sed -n 's/Vendor ID:[ \t]*//p')
CPUMODEL=$(lscpu | sed -n 's/Model name:[ \t]*//p')
BOOTMODE=$(cat /sys/firmware/efi/fw_platform_size)


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

echo -e "Version ${GREEN}$VERSION${NC}\n"
echo -e "CPU ${GREEN}$CPUVENDOR $CPUMODEL${NC}\n"

############################
# Test connection internet #
############################


################################
# Initialisation password ROOT #
################################
echo $ROOTPASSWORD | passwd root --stdin

####################
# Language clavier #
####################
loadkeys $LANGAGE
echo -e "Langage ${GREEN}$LANGAGE${NC}\n"

##################################
#  Initialisation du disque UEFI #
##################################
if [ "$BOOTMODE" = "64" ] || [ "$BOOTMODE" = "32" ]; then

echo -e "Boot Mode ${GREEN}UEFI${NC}"
echo ""
echo "Selectionner le dique systeme"
echo ""
lsblk -e7
echo ""
read disque
wipefs -a -f -q /dev/$disque

sfdisk -f -q /dev/$disque << EOF
label: gpt
,1G,U
;
write
EOF

mkfs.vfat /dev/"$disque"1
mkfs.ext4 /dev/"$disque"2
 
else
 
echo -e "${RED}BIOS${NC}"
echo -e "${RED}Installation sur BIOS legacy non pris en charge${NC}"

fi

mount /dev/"$disque"2 /mnt
mount --mkdir /dev/"$disque"1 /mnt/boot
pacstrap -K /mnt base
genfstab -U /mnt >> /mnt/etc/fstab

##########################
# Chroot nouveau systeme #
##########################
arch-chroot /mnt /bin/bash <<EOF
pacman -S --noconfirm nano sudo base-devel
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "fr_FR.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
echo "KEYMAP=fr" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl start systemd-networkd.service
systemctl start systemd-resolved.service

mkdir ~/kernelbuild
cd ~/kernelbuild

exit
EOF
# Unmount partitions
umount -R /mnt
