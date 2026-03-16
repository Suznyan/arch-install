#!/usr/bin/env bash
set -e

HOSTNAME="$1"
DOMAIN="$2"
USERNAME="$3"
PASSWORD="$4"
ROOT_PART="$5"

# Time

ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
hwclock --systohc

# Locale

sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Host

echo "$HOSTNAME" > /etc/hostname

cat <<HOSTS > /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOSTNAME.$DOMAIN $HOSTNAME
HOSTS

# Pacman tuning

sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

# Users

sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

useradd -m -G wheel -s /bin/bash "$USERNAME"

echo "root:$PASSWORD" | chpasswd
echo "$USERNAME:$PASSWORD" | chpasswd

# Services

systemctl enable NetworkManager
systemctl enable sshd

# Bootloader

bootctl install

ROOT_UUID=$(blkid -s PARTUUID -o value "$ROOT_PART")

mkdir -p /boot/loader/entries

cat <<BOOT > /boot/loader/loader.conf
default arch
timeout 3
editor no
BOOT

if [[ -n "$UCODE_IMG" ]]; then
INITRD_LINE="initrd $UCODE_IMG"
else
INITRD_LINE=""
fi

cat <<ENTRY > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
$INITRD_LINE
initrd /initramfs-linux.img
options root=PARTUUID=$ROOT_UUID rw
ENTRY

# Package install

bash /root/packages.sh "$USERNAME"
