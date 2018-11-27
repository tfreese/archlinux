#!/bin/bash
#
# Thomas Freese
#
# ArchLinux Installation Script: Prepare the Disks
#
#############################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
#############################################################################################################

set -euo pipefail
# –x für debug

# Partitionen löschen
parted /dev/sda rm 4;
parted /dev/sda rm 3;
parted /dev/sda rm 2;
parted /dev/sda rm 1;

# Filesystem bereinigen
mdadm --zero-superblock /dev/sda;
wipefs --all --force /dev/sda;

# Partition(en) anlegen
parted /dev/sda mklabel gpt;

# GRUB2
parted -a optimal /dev/sda mkpart primary 2048s 2MB;   # for gpt for grub
parted -a optimal /dev/sda mkpart primary 2MB 250GB;   # Windows
parted -a optimal /dev/sda mkpart primary 250GB 270GB; # swap
parted -a optimal /dev/sda mkpart primary 270GB 100%;  # root

parted /dev/sda set 1 bios_grub on;

#############################################################################################################
# Oder mit UEFI
#
# Prüfen, ob BIOS im UEFI Mode
efivar -l;
efibootmgr -v;
bootctl status;

# Verzeichniss muss vorhanden sein
ls /sys/firmware/efi;

# Devices ausgeben
lsblk;

parted -a optimal /dev/sda mkpart ESP fat32 2048s 500MB; # efiboot
parted -a optimal /dev/sda mkpart primary 500MB 5GB;		 # swap
parted -a optimal /dev/sda mkpart primary 5G 4TB;		     # raid

parted /dev/sda print;

parted /dev/sda set 1 esp on;
#parted /dev/sda set 2 swap on;
parted /dev/sda set 3 raid on;

parted /dev/sda name 1 efiboot;
parted /dev/sda name 2 swap;
parted /dev/sda name 3 raid;

parted /dev/sda print;

parted /dev/sda align-check opt 1;
parted /dev/sda align-check opt 2;
parted /dev/sda align-check opt 3;

# Partitions-Tabellen kopieren ZIEL <- QUELLE
sgdisk -R /dev/sdb /dev/sda;
sgdisk -R /dev/sdc /dev/sda;

## UUIDS neu vergeben
sgdisk -G /dev/sdb;
sgdisk -G /dev/sdc;

parted /dev/sdb print;
parted /dev/sdc print;

# Raids erstellen
mdadm --create --verbose /dev/md0 --metadata 1.0    --raid-devices=3 --level=1 /dev/sd[abc]1;
mdadm --create --verbose /dev/md1 --bitmap=internal --raid-devices=3 --level=5 --chunk=64 /dev/sd[abc]3;
#--force --assume-clean

# LVM erstellen
parted /dev/md1 set 1 lvm on;

pvcreate -v --dataalignment 64k /dev/md1;
vgcreate -v --dataalignment 64k vghost /dev/md1;

lvcreate -v --wipesignatures y -L 32G -n root vghost;
lvcreate -v --wipesignatures y -L 2G -n log vghost;
lvcreate -v --wipesignatures y -L 16G -n opt vghost;

# EFI Partion formatieren (FAT32)
mkfs.vfat -F 32 /dev/md0;

# System Partionen formatieren.
mkfs.ext4 -v -m 1 -b 4096 -E stride=16,stripe-width=32 -L root /dev/vghost/root;
mkfs.ext4 -v -m 0 -b 4096 -E stride=16,stripe-width=32 -L log /dev/vghost/log;
mkfs.ext4 -v -m 0 -b 4096 -E stride=16,stripe-width=32 -L opt /dev/vghost/opt;
# http://busybox.net/~aldot/mkfs_stride.html
# block size (file system block size) = 4096
# stripe-size (raid chunk size) = 64k
# stride = stripe-size / block size =  64k / 4k = 16
# stripe-width: stride * #-of-data-disks (3 disks RAID5 = 2 data disks) = 16 * 2 = 32

# Prüfung nach n mounts
tune2fs -c 30 /dev/vghost/root;
tune2fs -c 30 /dev/vghost/log;
tune2fs -c 30 /dev/vghost/opt;

# SWAP erstellen
mkswap -f /dev/sda2;
mkswap -f /dev/sdb2;
mkswap -f /dev/sdc2;
swapon -p 1 /dev/sda2;
swapon -p 1 /dev/sdb2;
swapon -p 1 /dev/sdc2;
