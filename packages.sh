#!/usr/bin/env bash
set -e

USERNAME="$1"

pacman -S --noconfirm \
plasma-desktop konsole dolphin kate ark spectacle kcalc \
plasma-systemmonitor plasma-nm plasma-pa powerdevil \
bluedevil bluez bluez-utils \
kdeconnect samba kio-extras \
sddm sddm-kcm polkit-kde-agent \
ffmpegthumbs kdegraphics-thumbnailers \
noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu \
adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts \
xdg-user-dirs xdg-utils wl-clipboard xclip \
pipewire pipewire-pulse pipewire-alsa wireplumber \
fcitx5 fcitx5-mozc fcitx5-configtool \
htop btop fastfetch tmux \
openssh zip unzip stow \
dnscrypt-proxy easyeffects qbittorrent \
krita gimp \
discord steam obs-studio \
android-tools scrcpy \
keepassxc lutris syncthing tor \
deadbeef mpv ffmpeg \
python

systemctl enable NetworkManager
systemctl enable sddm
systemctl enable bluetooth
systemctl enable sshd
systemctl enable dnscrypt-proxy
systemctl enable syncthing@$USERNAME

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
