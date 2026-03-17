#!/usr/bin/env bash
set -e

USERNAME="$1"

# Install packages
echo
echo "=== Package Installation ==="
echo "The following packages will be installed:"
echo "(large package set including KDE, gaming, multimedia, etc.)"
echo

read -rp "Proceed with installation? [y/N]: " CONFIRM

case "$CONFIRM" in
  [yY][eE][sS]|[yY]) ;;
  *) echo "Package installation skipped."; exit 0 ;;
esac

runuser -u "$USERNAME" -- yay -S --noconfirm --needed \
adobe-source-han-sans-jp-fonts \
adobe-source-han-serif-jp-fonts \
alsa-utils \
android-tools \
ark \
bluedevil \
bluez \
bluez-utils \
brave-bin \
btop \
byedpi-bin \
deadbeef \
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
lib32-vulkan-radeon \
librewolf-bin \
linux-headers \
lsp-plugins-lv2 \
lutris \
mesa \
mesa-utils \
mpv \
noto-fonts \
noto-fonts-cjk \
noto-fonts-emoji \
obs-studio \
opentabletdriver \
pcsx2-latest-bin \
pipewire \
pipewire-alsa \
pipewire-jack \
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
qdiskinfo-bin \
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
xdg-desktop-portal-kde \
xdg-user-dirs \
xdg-utils \
xorg-xwayland \
xwaylandvideobridge \
zip

systemctl enable sddm
systemctl enable bluetooth
