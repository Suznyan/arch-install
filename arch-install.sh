#!/usr/bin/env bash
set -euo pipefail

echo "=== Arch Linux Personal Installer ==="

# -------------------------------------------------

# Network Check

# -------------------------------------------------

echo "[INFO] Checking internet connectivity..."

if ! ping -c1 archlinux.org &>/dev/null; then
echo "[WARN] No internet detected."

```
echo "Scanning WiFi networks..."
nmcli dev wifi list

read -rp "SSID: " WIFI_SSID
read -rsp "Password: " WIFI_PASS
echo

nmcli dev wifi connect "$WIFI_SSID" password "$WIFI_PASS"

echo "[INFO] Rechecking connectivity..."
ping -c1 archlinux.org
```

fi

echo "[OK] Internet available."

# -------------------------------------------------

# Disk Selection

# -------------------------------------------------

echo
echo "Available disks:"
lsblk -d -o NAME,SIZE,MODEL

read -rp "Enter install disk (example: sda or nvme0n1): " DISK_NAME
DISK="/dev/$DISK_NAME"

echo
echo "WARNING: ALL DATA ON $DISK WILL BE DESTROYED."
read -rp "Type YES to continue: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
echo "Aborted."
exit 1
fi

# Detect partition prefix

if [[ "$DISK_NAME" == nvme* ]]; then
P1="${DISK}p1"
P2="${DISK}p2"
P3="${DISK}p3"
else
P1="${DISK}1"
P2="${DISK}2"
P3="${DISK}3"
fi

# -------------------------------------------------

# Partition Disk

# -------------------------------------------------

echo "[INFO] Partitioning disk..."

parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart EFI fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on

parted -s "$DISK" mkpart swap linux-swap 513MiB 33281MiB
parted -s "$DISK" mkpart root ext4 33281MiB 100%

# -------------------------------------------------

# Format

# -------------------------------------------------

echo "[INFO] Formatting partitions..."

mkfs.fat -F32 "$P1"
mkswap "$P2"
mkfs.ext4 "$P3"

# -------------------------------------------------

# Mount

# -------------------------------------------------

mount "$P3" /mnt
mkdir -p /mnt/boot
mount "$P1" /mnt/boot
swapon "$P2"

# -------------------------------------------------

# Base Install

# -------------------------------------------------

echo "[INFO] Installing base system..."

pacstrap /mnt 
base linux linux-firmware 
networkmanager sudo nano git curl wget

genfstab -U /mnt >> /mnt/etc/fstab

# -------------------------------------------------

# Collect User Info

# -------------------------------------------------

read -rp "Hostname: " HOSTNAME
read -rp "Domain name: " DOMAIN
read -rp "Username: " USERNAME
read -rsp "User password: " USERPASS
echo

# -------------------------------------------------

# Chroot Configuration Script

# -------------------------------------------------

cat <<EOF > /mnt/root/setup.sh
#!/usr/bin/env bash
set -e

echo "[INFO] Configuring system..."

# Timezone

ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
hwclock --systohc

# Locale

sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname

echo "$HOSTNAME" > /etc/hostname

cat <<HOSTS > /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOSTNAME.$DOMAIN $HOSTNAME
HOSTS

# Sudo

sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Users

useradd -m -G wheel -s /bin/bash $USERNAME
echo "root:$USERPASS" | chpasswd
echo "$USERNAME:$USERPASS" | chpasswd

# Enable services

systemctl enable NetworkManager
systemctl enable sshd

# Install desktop + packages

pacman -S --noconfirm 
plasma-meta kde-applications-meta 
sddm 
pipewire pipewire-pulse wireplumber 
fcitx5 fcitx5-mozc fcitx5-configtool 
git nano curl wget htop btop fastfetch tmux 
openssh zip unzip stow 
dnscrypt-proxy easyeffects qbittorrent 
opentabletdriver krita gimp 
android-tools scrcpy 
keepassxc lutris 
deadbeef mpv yt-dlp ffmpeg 
python pcsx2

systemctl enable sddm
systemctl enable dnscrypt-proxy

# Bootloader

bootctl install

ROOT_UUID=$(blkid -s PARTUUID -o value $P3)

mkdir -p /boot/loader/entries

cat <<BOOT > /boot/loader/loader.conf
default arch
timeout 3
editor no
BOOT

cat <<ENTRY > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=PARTUUID=$ROOT_UUID rw
ENTRY

# Install yay

cd /opt
git clone https://aur.archlinux.org/yay.git
chown -R $USERNAME:$USERNAME yay
cd yay
sudo -u $USERNAME makepkg -si --noconfirm

# AUR packages

sudo -u $USERNAME yay -S --noconfirm 
librewolf-bin brave-bin byedpi

echo "[INFO] Setup complete."
EOF

chmod +x /mnt/root/setup.sh

# Run chroot

arch-chroot /mnt /root/setup.sh

# Cleanup

rm /mnt/root/setup.sh

echo
echo "Installation complete."
echo "Unmounting..."

umount -R /mnt
swapoff "$P2"

echo "Rebooting..."

reboot
