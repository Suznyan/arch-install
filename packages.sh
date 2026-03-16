#!/usr/bin/env bash
set -e

USERNAME="$1"

sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
pacman -Syy

pacman -S --noconfirm \
adobe-source-han-sans-jp-fonts \
adobe-source-han-serif-jp-fonts \
alsa-utils \
android-tools \
ark \
bluedevil \
bluez \
bluez-utils \
btop \
discord \
dnscrypt-proxy \
dolphin \
easyeffects \
fastfetch \
fcitx5 \
fcitx5-configtool \
fcitx5-mozc \
ffmpeg \
ffmpegthumbs \
gamemode \
gimp \
gst-libav \
gst-plugin-pipewire \
gst-plugins-bad \
gst-plugins-ugly \
htop \
kate \
kcalc \
kdeconnect \
kdegraphics-thumbnailers \
keepassxc \
kio-admin \
kio-extras \
kio-fuse \
konsole \
krita \
kscreen \
kwayland-integration \
linux-headers \
lutris \
mesa \
mesa-utils \
mpv \
noto-fonts \
noto-fonts-cjk \
noto-fonts-emoji \
obs-studio \
openssh \
pipewire \
pipewire-alsa \
pipewire-pulse \
plasma-browser-integration \
plasma-desktop \
plasma-nm \
plasma-pa \
plasma-systemmonitor \
polkit-kde-agent \
power-profiles-daemon \
powerdevil \
python \
qbittorrent \
samba \
scrcpy \
sddm \
sddm-kcm \
sof-firmware \
spectacle \
steam \
stow \
syncthing \
tmux \
tor \
ttf-dejavu \
unzip \
vulkan-radeon \
wireplumber \
wl-clipboard \
xclip \
xdg-user-dirs \
xdg-utils \
xorg-xwayland \
zip

systemctl enable NetworkManager
systemctl enable sddm
systemctl enable bluetooth
systemctl enable sshd
systemctl enable dnscrypt-proxy
systemctl enable syncthing@$USERNAME

# zram if no swap

if ! grep -q swap /etc/fstab; then
pacman -S --noconfirm zram-generator
fi

# Install yay

cd /opt
git clone https://aur.archlinux.org/yay.git
chown -R "$USERNAME:$USERNAME" yay
cd yay

sudo -u "$USERNAME" makepkg -si --noconfirm

# AUR packages

sudo -u "$USERNAME" yay -S --noconfirm \
librewolf-bin \
brave-bin \
byedpi-bin \
pcsx2-latest-bin \
opentabletdriver \
qdiskinfo-bin \
deadbeef \
xwaylandvideobridge
