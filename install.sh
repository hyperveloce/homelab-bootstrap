#!/bin/bash

# Check if Script is Run as Root
if [[ $EUID -ne 0 ]]; then
 echo "You must be a root user to run this script, please run sudo ./install.sh" 2>&1
 exit 1
fi

username=$(id -u -n 1000)
builddir=$(pwd)

# Load package list from config/$(hostname).config
host_config="configs/$(hostname).config"
if [[ -f "$host_config" ]]; then
    source "$host_config"
    echo -e "\e[1;33mInstalling packages from: $host_config\e[0m"
else
    echo -e "\e[1;31mHost-specific config not found: $host_config\e[0m"
    exit 1
fi

# Install Terminus Fonts
sudo apt install fonts-terminus

# Set the font to Terminus Fonts
setfont /usr/share/consolefonts/Uni3-TerminusBold28x14.psf.gz

# Clear the screen
clear

# System setup
#sudo hostnamectl set-hostname hyperveloce
sudo timedatectl set-timezone Australia/Melbourne

# user setup
sudo adduser kanasu
sudo usermod -aG sudo kanasu

# firewall setup
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp  # or the port you set for SSH
sudo ufw enable

# brute force protection
sudo apt install fail2ban
sudo systemctl enable fail2ban

# Update packages list and update system
apt update
apt upgrade -y

# Install nala
apt install nala -y

# Making .config and Moving config files and background to Pictures
cd $builddir
mkdir -p /home/$username/.config
mkdir -p /home/$username/.fonts
mkdir -p /home/$username/.themes
mkdir -p /home/$username/Pictures
mkdir -p /home/$username/Pictures/bg
cp -R dotconfig/* /home/$username/.config/
cp bg/bg.jpg /home/$username/Pictures/bg/
cp themes /home/$username/.themes
mv user-dirs.dirs /home/$username/.config
chown -R $username:$username /home/$username

# ------------------------------------------------- #
# ----- INSTALL Debian APT AVAILABLE SOFTWARE ----- #
# ------------------------------------------------- #

sudo apt install -y $PACKAGES

# sudo apt install -y \

# # 🛠️ System Tools
# stacer \
# timeshift \
# barrier \
# btop \
# picom \
# dupeguru \
# qjackctl \
# xarchiver \
# curl \
# x11-xserver-utils \
# unzip \
# wget \
# preload \
# build-essential \
# zoxide \
# flatpak \
# gnome-software-plugin-flatpak \
# synaptic \
# gnome-tweaks \
# gnome-shell-extension-manager \
# gnome-power-manager \

# # 🌐 Networking & Remote Access
# network-manager \
# network-manager-gnome \
# network-manager-openvpn \
# network-manager-openvpn-gnome \

# # 🌍 Web Browsers
# brave-browser \
# librewolf \
# chromium \

# # 🖼️ Image & Media Utilities
# feh \
# geeqie \
# shotwell \
# org.darktable.darktable \
# papirus-icon-theme \
# fonts-noto-color-emoji \

# # 🧰 Developer & Power User Tools
# kitty \
# neovim \
# cmatrix \
# diodon \
# vim \

# # 🎭 Miscellaneous & Fun
# hollywood \
# fastfetch

# # Packages needed for window manager installation
# sudo apt install -y picom nitrogen rofi dunst libnotify-bin wmctrl xdotool

# dpkg --list | grep <package>

apt purge libreoffice* -y
apt purge firefox-esr gnome-contacts rhythmbox cheese iagno lightsoff four-in-a-row gnome-robots pegsolitaire gnome-2048 hitori gnome-klotski gnome-mines gnome-mahjongg gnome-sudoku quadrapassel swell-foop gnome-tetravex gnome-taquin aisleriot gnome-chess five-or-more gnome-nibbles tali gnome-weather gnome-online-accounts gnome-music gnome-sound-recorder gnome-maps gnome-calendar gnome-music gnome-text-editor transmission-common transmission-gtk firefox-esr evolution -y

# Download Nordic Theme
cd /usr/share/themes/
git clone https://github.com/EliverLara/Nordic.git

# Installing fonts
cd $builddir
nala install fonts-font-awesome -y
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
unzip FiraCode.zip -d /home/$username/.fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Meslo.zip
unzip Meslo.zip -d /home/$username/.fonts
mv dotfonts/fontawesome/otfs/*.otf /home/$username/.fonts/
chown $username:$username /home/$username/.fonts/*

# Reloading Font
fc-cache -vf
# Removing zip Files
rm ./FiraCode.zip ./Meslo.zip

# Install Nordzy cursor
git clone https://github.com/alvatip/Nordzy-cursors
cd Nordzy-cursors
./install.sh
cd $builddir
rm -rf Nordzy-cursors

# Enable wireplumber audio service

sudo -u $username systemctl --user enable wireplumber.service
apt autoremove

# Beautiful bash
bash scripts/setup.sh

# Use nala
bash scripts/usenala

# Add Syncthing repo key
curl -s https://syncthing.net/release-key.txt | sudo apt-key add -
# Add Syncthing repo
echo "deb https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
# Update and install
sudo apt update
sudo apt install syncthing -y

# ----- FLATPAK ----- #

# Add Flathub repo if not already added
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Flatpak apps system-wide from Flathub
if [[ ${#FLATPAKS[@]} -gt 0 ]]; then
  echo -e "\e[1;33mInstalling Flatpak packages...\e[0m"
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  for app in "${FLATPAKS[@]}"; do
    flatpak install -y --system flathub "$app"
  done
else
  echo -e "\e[1;34mNo Flatpak apps listed in config for this host.\e[0m"
fi

# Install Zed
curl -f https://zed.dev/install.sh | sh

# Neovim
sudo apt-get install neovim
sudo apt-get install python3-neovim

# Install Brave
curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
apt update
apt install brave-browser

# Install librewolf
wget -O- https://deb.librewolf.net/keyring.gpg | sudo tee /usr/share/keyrings/librewolf-keyring.gpg
sudo apt update && sudo apt install librewolf -y

# fastfetch
echo 'deb http://download.opensuse.org/repositories/home:/guideos/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/home:guideos.list
curl -fsSL https://download.opensuse.org/repositories/home:guideos/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_guideos.gpg > /dev/null
apt update
apt install fastfetch

# ----- Set gnome-extensions ----- #
gnome-extensions install --force customreboot@nova1545.zip && gnome-extensions enable customreboot@nova1545
gnome-extensions install --force openweather-extension@jenslody.de.zip && gnome-extensions enable openweather-extension@jenslody.de
gnome-extensions install --force openbar@neuromorph.zip && gnome-extensions enable openbar@neuromorph
gnome-extensions install --force Vitals@CoreCoding.com.zip && gnome-extensions enable Vitals@CoreCoding.com
gnome-extensions install --force blur-my-shell@aunetx.zip && gnome-extensions enable blur-my-shell@aunetx
gnome-extensions install --force unblank@sun.wxg@gmail.com.zip && gnome-extensions enable unblank@sun.wxg@gmail.com

gnome-extensions enable customreboot@nova1545 || true
gnome-extensions enable openweather-extension@jenslody.de || true
gnome-extensions enable openbar@neuromorph || true
gnome-extensions enable Vitals@CoreCoding.com || true
gnome-extensions enable blur-my-shell@aunetx || true
gnome-extensions enable unblank@sun.wxg@gmail.com || true
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com || true

# ----- Setup GNOME Desktop ----- #
# Set GNOME tweaks settings
cp bg/bg.jpg /home/kanasu/Pictures/bg/
gsettings set org.gnome.desktop.background picture-uri-dark "/home/kanasu/Pictures/bg/bg.jpg"
dconf load / < gnome/gnome-settings.ini
gsettings get org.gnome.shell favorite-apps
gsettings set org.gnome.shell favorite-apps "['thunar.desktop', 'kitty.desktop', 'chromium.desktop', 'brave-browser.desktop', 'io.atom.Atom.desktop', 'com.mastermindzh.tidal-hifi.desktop', 'io.github.mimbrero.WhatsAppDesktop.desktop']"
gsettings set org.gnome.desktop.interface enable-animations false

# printf "\e[1;32mYour system is ready and will go for reboot! Thanks you.\e[0m\n"

# systemctl reboot
