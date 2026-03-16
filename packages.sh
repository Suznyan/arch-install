#!/usr/bin/env bash
set -e

USERNAME="$1"

pacman -S --noconfirm 
adobe-source-han-sans-jp-fonts
adobe-source-han-serif-jp-fonts
plasma-meta kde-applications-meta sddm 
pipewire pipewire-pulse wireplumber 
fcitx5 fcitx5-mozc fcitx5-configtool 
htop btop fastfetch tmux 
openssh zip unzip stow 
dnscrypt-proxy easyeffects qbittorrent
krita gimp 
discord steam obs-studio
android-tools scrcpy 
keepassxc lutris syncthing tor
deadbeef mpv ffmpeg 
python

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
librewolf-bin brave-bin byedpi-bin pcsx2-latest-bin
opentabletdriver qdiskinfo-bin
