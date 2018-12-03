#!/bin/bash
#
# Thomas Freese
#
# ArchLinux Installation Script: Initial pacstrap and arch-chroot
#
#############################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
#############################################################################################################

set -euo pipefail
# –x für debug

# System-Partition mounten
mount /dev/vghost/root /mnt;

# Boot-Partition mounten: EFI / GRUP2
mkdir /mnt/boot;
mount /dev/md0 /mnt/boot;

# Home-Partition
mkdir -p /mnt/home;
mount /dev/vghost/home /mnt/home;

# Log-Partition
mkdir -p /mnt/var/log;
mount /dev/vghost/log /mnt/var/log;

# Opt-Partition
mkdir /mnt/opt;
mount /dev/vghost/opt /mnt/opt;

pacstrap /mnt base;
#pacstrap /mnt base base-devel;

genfstab -U -p /mnt >> /mnt/etc/fstab;

echo " " >> /mnt/etc/fstab;
echo "Swap-Prio: DEVICE     none  swap   defaults,pri=1   0 0" >> /mnt/etc/fstab;
echo "#Bei SSD fstab Eintrag ändern in" >> /mnt/etc/fstab;
echo "#/dev/sda4	/	ext4	rw,defaults,noatime,nodiratime,discard	0	1" >> /mnt/etc/fstab;
echo "#NICHT /dev/sda4	/	ext4	rw,relatime,data=ordered	0	1" >> /mnt/etc/fstab;

arch-chroot /mnt;
