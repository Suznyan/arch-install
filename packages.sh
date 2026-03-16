#!/usr/bin/env bash
set -e

USERNAME="$1"

pacman -S --noconfirm 
plasma-meta kde-applications-meta sddm 
pipewire pipewire-pulse wireplumber 
fcitx5 fcitx5-mozc fcitx5-configtool 
htop btop fastfetch tmux 
openssh zip unzip stow 
dnscrypt-proxy easyeffects qbittorrent 
opentabletdriver krita gimp 
android-tools scrcpy 
keepassxc lutris 
deadbeef mpv yt-dlp ffmpeg 
python pcsx2

systemctl enable sddm
systemctl enable dnscrypt-proxy

# zram if no swap

if ! grep -q swap /etc/fstab; then
pacman -S --noconfirm systemd-zram-generator
fi

# Install yay

cd /opt
git clone https://aur.archlinux.org/yay.git
chown -R "$USERNAME:$USERNAME" yay
cd yay

sudo -u "$USERNAME" makepkg -si --noconfirm

# AUR packages

sudo -u "$USERNAME" yay -S --noconfirm 
librewolf-bin brave-bin byedpi
