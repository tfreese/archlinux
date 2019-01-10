#!/bin/bash
#
# Thomas Freese
#
# ArchLinux Installation Script: Install the BootLoader
#
#############################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
#############################################################################################################

set -euo pipefail
# –x für debug

pacman --noconfirm --needed -S efibootmgr;

#############################################################################################################
# Prüfen, ob BIOS im UEFI Mode
efivar -l;
efibootmgr -v;
bootctl status;

# Verzeichnis muss vorhanden sein
ls /sys/firmware/efi;

# Devices ausgeben
lsblk -o NAME,LABEL,SIZE,FSTYPE,TYPE,MOUNTPOINT,MODEL,UUID;

#############################################################################################################
# UEFI

mkdir -p /boot/EFI/systemd;
mkdir -p /boot/EFI/BOOT;

# bootctl ist im systemd Package enthalten
bootctl install;
# Bei Raid wird 'bootctl install' nicht funktionieren, daher manuell installieren.
efibootmgr --create --disk /dev/sda --part 1 --label ArchLinux\ 1 --loader \\EFI\\systemd\\systemd-bootx64.efi;
efibootmgr --create --disk /dev/sdb --part 1 --label ArchLinux\ 2 --loader \\EFI\\systemd\\systemd-bootx64.efi;
efibootmgr --create --disk /dev/sdc --part 1 --label ArchLinux\ 3 --loader \\EFI\\systemd\\systemd-bootx64.efi;

bootctl update;
# Kopiert /usr/lib/systemd/boot/efi/systemd-bootx64.efi nach
# - /boot/EFI/systemd/systemd-bootx64.efi
# - /boot/EFI/BOOT/BOOTX64.EFI
# Bei Raid wird 'bootctl update' nicht funktionieren, daher manuell installieren.
cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /boot/EFI/systemd/systemd-bootx64.efi;
cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /boot/EFI/BOOT/BOOTX64.EFI;

# Bei einem Update von systemd-boot müssen die neuen *.efi Dateien wieder nach /boot/EFI kopiert werden.
# Manuell mit bootctl update;
# oder
# automatisch per pacman-Hook:
cat << EOF > /etc/pacman.d/hooks/systemd-boot.hook
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot
When = PostTransaction
# Exec = /usr/bin/bootctl update
Exec = /etc/pacman.d/hooks/systemd-boot.sh
# Exec = /usr/bin/cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /boot/EFI/systemd/systemd-bootx64.efi;
# Exec = /usr/bin/cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /boot/EFI/BOOT/BOOTX64.EFI;
EOF

cat << EOF > /etc/pacman.d/hooks/systemd-boot.sh
#!/bin/bash

/usr/bin/cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /boot/EFI/systemd/systemd-bootx64.efi;
/usr/bin/cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /boot/EFI/BOOT/BOOTX64.EFI;
EOF

chmod 700 /etc/pacman.d/hooks/systemd-boot.hook;
chmod 700 /etc/pacman.d/hooks/systemd-boot.sh;


mkdir -p /boot/loader/entries;

cat << EOF > /boot/loader/loader.conf
default archlinux
timout 5
editor 0
EOF

cat << EOF > /boot/loader/entries/archlinux.conf
title ArchLinux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=/dev/vghost/root rw
# options root=/dev/md1 rw
# options root=PARTUUID=<PARTUUID aus blkid> rw
# options root=LABEL=... rw
# options root=UUID=... rw
EOF

# cp /boot/loader/entries/archlinux.conf /boot/loader/entries/archlinux-fallback.conf;

cat << EOF > /boot/loader/entries/archlinux-fallback.conf
title ArchLinux-Fallback
linux /vmlinuz-linux
initrd /initramfs-linux-fallback.img
options root=/dev/vghost/root rw
EOF

exit;
reboot;


#############################################################################################################
# GRUB2 (Legacy Boot)

pacman --noconfirm --needed -S grub os-prober;

#sed -i_"$TIME" 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub;
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub;

mkdir /boot/grub;
grub-mkconfig -o /boot/grub/grub.cfg;
grub-install --target=i386-pc --recheck /dev/sda;
grub-install --target=i386-pc --recheck /dev/sdb;
grub-install --target=i386-pc --recheck /dev/sdc;

exit;
reboot;


#############################################################################################################
# SYSLINUX (Legacy Boot)

pacman --noconfirm --needed -S syslinux;

# -i (install the files)
# -a (mark the partition active with the boot flag)
# -m (install the MBR boot code)
syslinux-install_update -i -a -m;

# Edit
nano /boot/syslinux/syslinux.cfg;
# APPEND root=/dev/vgvm/root rw

exit;
reboot;


#############################################################################################################

efimootmgr:
-c; --create	= create new variable bootnum and add to bootorder
-d; --disk		= (defaults to /dev/sda) containing loader
-p; --part		= (defaults to 1) containing loader
-L; --label		= Boot manager display label (defaults to "Linux")
-l; --loader	= (defaults to "\EFI\/boot/EFI\grub.efi")
-u; --unicode	= handle extra args as UCS-2 (default is ASCII)
-v; --verbose	= print additional information

# gptfdisk

# vim
# Ausgabe von Befehl einfügen: :r!unix_command
# Zeile löschen: dd


efibootmgr -c -d /dev/sda -p 1 -L Arch\ Linux\ 1 -l \\EFI\\gummiboot\\gummibootx64.efi
efibootmgr -c -d /dev/sdb -p 1 -L Arch\ Linux\ 2 -l \\EFI\\gummiboot\\gummibootx64.efi

efibootmgr --create --disk /dev/sda --part 1 --label "Precise - GRUB2" --loader \\EFI\\ubuntu\\grubx64.efi
efibootmgr --create --disk /dev/sda --part 2 --label "Fedora Grub" --loader /EFI/fedora/grubx64.efi
efibootmgr --create --disk /dev/sda --part 3 --label "rEFInd Boot Manager" --loader /EFI/refind/refind_x64.efi --verbose
efibootmgr --disk /dev/sdX --part Y --create --label "Arch Linux" --loader /vmlinuz-linux --unicode 'root=PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX rw initrd=\initramfs-linux.img' --verbose
efibootmgr -c -d /dev/sda -p 1 -l \vmlinuz-linux -L "Arch Linux efistub" -u "initrd=/initramfs-linux.img root=LABEL=p_arch rw"
efibootmgr -c -d /dev/sda -p 1 -l \vmlinuz-linux -L "Arch Linux fallback efistub" -u "initrd=/initramfs-linux-fallback.img root=LABEL=p_arch rw"
