#!/usr/bin/env bash
set -euo pipefail

### =========================
### Utility Functions
### =========================

die() {
  echo "ERROR: $*" >&2
  exit 1
}

get_part() {
  local num="$1"
  if [[ "$DISK_NAME" == nvme* ]]; then
    echo "${DISK}p${num}"
  else
    echo "${DISK}${num}"
  fi
}

### =========================
### Network
### =========================

setup_network() {
  echo "=== Network Check ==="

  if ! ping -c1 archlinux.org &>/dev/null; then
    echo "No internet detected."
    nmcli dev wifi list
    read -rp "SSID: " WIFI_SSID
    read -rsp "Password: " WIFI_PASS; echo
    nmcli dev wifi connect "$WIFI_SSID" password "$WIFI_PASS"
  fi
}

### =========================
### Disk Selection
### =========================

select_disk() {
  echo "=== Disk Selection ==="

  LIVE_DEVICE=$(lsblk -no pkname "$(findmnt -n -o SOURCE /run/archiso/bootmnt)" 2>/dev/null || true)
  LIVE_DEVICE="/dev/${LIVE_DEVICE:-}"

  lsblk -d -o NAME,SIZE,MODEL

  while true; do
    read -rp "Enter install disk (e.g. sda, nvme0n1): " DISK_NAME
    DISK="/dev/$DISK_NAME"

    [[ -b "$DISK" ]] || { echo "Invalid disk"; continue; }
    [[ "$DISK" == "$LIVE_DEVICE" ]] && { echo "Cannot use live ISO disk"; continue; }

    break
  done

  echo "This will ERASE: $DISK"
  read -rp "Type '$DISK_NAME' to confirm: " CONFIRM
  [[ "$CONFIRM" == "$DISK_NAME" ]] || die "Confirmation failed"
}

### =========================
### Partition Config
### =========================

partition_config() {
  echo "=== Partition Configuration ==="

  echo "1) Root only"
  echo "2) Root + Home"
  read -rp "Choose layout: " LAYOUT

  read -rp "EFI size in MiB (default 512): " EFI_SIZE
  EFI_SIZE=${EFI_SIZE:-512}

  read -rp "Swap size in GB (0 for none): " SWAPSIZE

  if [[ "$LAYOUT" == "2" ]]; then
    read -rp "Root size in GB: " ROOT_SIZE
  fi
}

### =========================
### Partition Disk
### =========================

partition_disk() {
  echo "=== Partitioning Disk ==="

  parted -s "$DISK" mklabel gpt

  EFI_END=$((1 + EFI_SIZE))
  CURRENT=$EFI_END
  PART_INDEX=1

  # EFI
  parted -s "$DISK" mkpart EFI fat32 1MiB "${EFI_END}MiB"
  parted -s "$DISK" set 1 esp on
  ((PART_INDEX++))

  # Swap
  if [[ "$SWAPSIZE" != "0" ]]; then
    SWAP_END=$((CURRENT + SWAPSIZE * 1024))
    parted -s "$DISK" mkpart swap linux-swap "${CURRENT}MiB" "${SWAP_END}MiB"
    SWAP_PART_NUM=$PART_INDEX
    CURRENT=$SWAP_END
    ((PART_INDEX++))
  fi

  # Root / Home
  if [[ "$LAYOUT" == "2" ]]; then
    ROOT_END=$((CURRENT + ROOT_SIZE * 1024))
    parted -s "$DISK" mkpart root ext4 "${CURRENT}MiB" "${ROOT_END}MiB"
    ROOT_PART_NUM=$PART_INDEX
    ((PART_INDEX++))

    parted -s "$DISK" mkpart home ext4 "${ROOT_END}MiB" 100%
    HOME_PART_NUM=$PART_INDEX
  else
    parted -s "$DISK" mkpart root ext4 "${CURRENT}MiB" 100%
    ROOT_PART_NUM=$PART_INDEX
  fi

  # Resolve device paths
  EFI_PART=$(get_part 1)
  ROOT_PART=$(get_part "$ROOT_PART_NUM")

  [[ -n "${SWAP_PART_NUM:-}" ]] && SWAP_PART=$(get_part "$SWAP_PART_NUM")
  [[ -n "${HOME_PART_NUM:-}" ]] && HOME_PART=$(get_part "$HOME_PART_NUM")
}

### =========================
### Format + Mount
### =========================

format_and_mount() {
  echo "=== Formatting ==="

  mkfs.fat -F 32 "$EFI_PART"
  mkfs.ext4 "$ROOT_PART"

  [[ -n "${HOME_PART:-}" ]] && mkfs.ext4 "$HOME_PART"

  if [[ -n "${SWAP_PART:-}" ]]; then
    mkswap "$SWAP_PART"
    swapon "$SWAP_PART"
  fi

  echo "=== Mounting ==="

  mount "$ROOT_PART" /mnt
  mount -m "$EFI_PART" /mnt/boot

  [[ -n "${HOME_PART:-}" ]] && mount -m "$HOME_PART" /mnt/home
}

### =========================
### Mirrors
### =========================

setup_mirrors() {
  pacman -Sy --noconfirm reflector

  reflector \
    --latest 50 \
    --protocol https \
    --sort rate \
    --save /etc/pacman.d/mirrorlist
}

### =========================
### Base Install
### =========================

install_base() {
  echo "=== Installing Base System ==="

  CPU_VENDOR=$(grep -m1 "vendor_id" /proc/cpuinfo)

  if [[ "$CPU_VENDOR" == *"AuthenticAMD"* ]]; then
    MICROCODE="amd-ucode"
  elif [[ "$CPU_VENDOR" == *"GenuineIntel"* ]]; then
    MICROCODE="intel-ucode"
  else
    MICROCODE=""
  fi

  pacstrap -K /mnt base base-devel linux linux-firmware $MICROCODE \
    networkmanager sudo git nano curl wget reflector

  genfstab -U /mnt >> /mnt/etc/fstab
}

### =========================
### User Setup
### =========================

collect_user_info() {
  read -rp "Hostname: " HOSTNAME
  read -rp "Domain: " DOMAIN
  read -rp "Username: " USERNAME
  read -rsp "Password: " PASSWORD; echo
}

### =========================
### Main
### =========================

main() {
  echo "=== Arch Installer (Modular) ==="

  setup_network
  select_disk
  partition_config
  partition_disk
  format_and_mount
  setup_mirrors
  install_base
  collect_user_info

  cp chroot-setup.sh /mnt/root/
  cp packages.sh /mnt/root/

  arch-chroot /mnt /root/chroot-setup.sh \
    "$HOSTNAME" "$DOMAIN" "$USERNAME" "$PASSWORD" "$ROOT_PART"

  umount -R /mnt
  echo "Install complete. Rebooting..."
  reboot
}

main "$@"
