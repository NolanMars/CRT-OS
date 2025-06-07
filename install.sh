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

echo "Version"
echo -e "Version ${GREEN}$VERSION${NC}\n"

echo "CPU"
echo -e "${GREEN}$CPUVENDOR$CPUMODEL${NC}\n"

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
echo "Langage"
loadkeys $LANGAGE
echo -e "${GREEN}$LANGAGE${NC}\n"

##################################
#  Initialisation du disque UEFI #
##################################

if [ "$BOOTMODE" = "64" ] || [ "$BOOTMODE" = "32" ]; then

echo "Boot Mode"

echo -e "${GREEN}UEFI${NC}"

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

# Chroot into new system
arch-chroot /mnt /bin/bash <<EOF

pacman -S nano sudo

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

hwclock --systohc

exit
EOF
# Unmount partitions
umount -R /mnt
