#!/usr/bin/env bash
set -euo pipefail

echo "=== Arch Linux Installer ==="

# Internet check

if ! ping -c1 archlinux.org &>/dev/null; then
echo "No internet detected."
nmcli dev wifi list
read -rp "SSID: " WIFI_SSID
read -rsp "Password: " WIFI_PASS
echo
nmcli dev wifi connect "$WIFI_SSID" password "$WIFI_PASS"
fi

# Disk selection
LIVE_DEVICE=$(lsblk -no pkname "$(findmnt -n -o SOURCE /run/archiso/bootmnt)" 2>/dev/null || true)
LIVE_DEVICE="/dev/${LIVE_DEVICE:-}"
echo "Available disks:"
lsblk -d -o NAME,SIZE,MODEL
while true; do
read -rp "Enter install disk (example: sda or nvme0n1): " DISK_NAME
DISK="/dev/$DISK_NAME"

if [[ ! -b "$DISK" ]]; then
echo "Disk does not exist."
continue
fi

if [[ "$DISK" == "$LIVE_DEVICE" ]]; then
echo "ERROR: Cannot install to the live ISO disk."
continue
fi

break
done

echo
echo "This will ERASE:"
echo "$DISK"

read -rp "Type the disk name ($DISK_NAME) to confirm: " CONFIRM

if [[ "$CONFIRM" != "$DISK_NAME" ]]; then
echo "Confirmation failed."
exit 1
fi

# Partition naming

if [[ "$DISK_NAME" == nvme* ]]; then
P1="${DISK}p1"
P2="${DISK}p2"
P3="${DISK}p3"
else
P1="${DISK}1"
P2="${DISK}2"
P3="${DISK}3"
fi

# Swap prompt

read -rp "Swap size in GB (0 for none): " SWAPSIZE

# Partition disk

parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart EFI fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on

if [[ "$SWAPSIZE" != "0" ]]; then
SWAP_END=$((513 + SWAPSIZE * 1024))
parted -s "$DISK" mkpart swap linux-swap 513MiB "${SWAP_END}MiB"
parted -s "$DISK" mkpart root ext4 "${SWAP_END}MiB" 100%
else
parted -s "$DISK" mkpart root ext4 513MiB 100%
fi

# Format

mkfs.fat -F32 "$P1"

if [[ "$SWAPSIZE" != "0" ]]; then
mkswap "$P2"
mkfs.ext4 "$P3"
ROOT="$P3"
else
mkfs.ext4 "$P2"
ROOT="$P2"
fi

# Mount

mount "$ROOT" /mnt
mkdir /mnt/boot
mount "$P1" /mnt/boot

if [[ "$SWAPSIZE" != "0" ]]; then
swapon "$P2"
fi

# Mirrors

pacman -Sy --noconfirm reflector \
--country Japan,Singapore,Taiwan,Korea 
--age 12 
--protocol https 
--sort rate 
--save /etc/pacman.d/mirrorlist

# Base system
CPU_VENDOR=$(grep -m1 "vendor_id" /proc/cpuinfo)

if [[ "$CPU_VENDOR" == *"AuthenticAMD"* ]]; then
MICROCODE="amd-ucode"
UCODE_IMG="/amd-ucode.img"
elif [[ "$CPU_VENDOR" == *"GenuineIntel"* ]]; then
MICROCODE="intel-ucode"
UCODE_IMG="/intel-ucode.img"
else
MICROCODE=""
UCODE_IMG=""
fi

echo "Detected CPU vendor: $CPU_VENDOR"
echo "Installing microcode package: $MICROCODE"

pacstrap /mnt base base-devel linux linux-firmware $MICROCODE \
networkmanager sudo git nano curl wget reflector

genfstab -U /mnt >> /mnt/etc/fstab

# Copy install scripts

cp chroot-setup.sh /mnt/root/
cp packages.sh /mnt/root/

# User prompts

read -rp "Hostname: " HOSTNAME
read -rp "Domain: " DOMAIN
read -rp "Username: " USERNAME
read -rsp "Password: " PASSWORD
echo

arch-chroot /mnt /root/chroot-setup.sh "$HOSTNAME" "$DOMAIN" "$USERNAME" "$PASSWORD" "$ROOT"

umount -R /mnt
echo "Install finished. Rebooting..."
reboot
