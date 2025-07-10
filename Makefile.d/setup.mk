SUDO := sudo
BUILD_DIR := $(shell pwd)
HOSTNAME := $(shell hostname)
CONFIG_DIR := config
CONFIG_FILE := $(CONFIG_DIR)/$(HOSTNAME).config

# Check for config existence and stop if missing
ifeq ("$(wildcard $(CONFIG_FILE))","")
$(error Config file '$(CONFIG_FILE)' not found! Please create it and rerun the Makefile.)
else
-include $(CONFIG_FILE)
endif

.PHONY: all check-root system-setup user-setup firewall setup-folders install-packages fonts services flatpak gnome-extensions gnome-settings reboot

all: check-root system-setup user-setup firewall setup-folders install-packages fonts services flatpak gnome-extensions gnome-settings reboot

check-root:
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "Please run as root or with sudo"; \
		exit 1; \
	fi

system-setup:
	@echo "Setting hostname to $(HOSTNAME) and timezone to $(TIMEZONE)"
	$(SUDO) hostnamectl set-hostname $(HOSTNAME)
	$(SUDO) timedatectl set-timezone $(TIMEZONE)
	$(SUDO) apt update && $(SUDO) apt upgrade -y

user-setup:
	@echo "Creating user $(USERNAME) and adding to sudo group"
	-$(SUDO) adduser --disabled-password --gecos "" $(USERNAME) || echo "User exists"
	$(SUDO) usermod -aG sudo $(USERNAME)

firewall:
	@echo "Installing and configuring firewall..."
	$(SUDO) apt install ufw -y
	$(SUDO) ufw default deny incoming
	$(SUDO) ufw default allow outgoing
	$(SUDO) ufw allow $(SSH_PORT)/tcp
	$(SUDO) ufw --force enable

setup-folders:
	@echo "Creating config folders and copying configs for user $(USERNAME)..."
	mkdir -p /home/$(USERNAME)/.config /home/$(USERNAME)/.fonts /home/$(USERNAME)/.themes /home/$(USERNAME)/Pictures/bg
	cp -r dotconfig/* /home/$(USERNAME)/.config/
	cp bg/bg.jpg /home/$(USERNAME)/Pictures/bg/
	cp -r themes/* /home/$(USERNAME)/.themes/
	mv user-dirs.dirs /home/$(USERNAME)/.config/
	chown -R $(USERNAME):$(USERNAME) /home/$(USERNAME)

install-packages:
	@echo "Installing packages: $(PACKAGES)"
	$(SUDO) apt install -y $(PACKAGES)

fonts:
	@echo "Installing fonts..."
	$(SUDO) apt install fonts-font-awesome -y
	cp -r fonts/* /home/$(USERNAME)/.fonts/
	chown -R $(USERNAME):$(USERNAME) /home/$(USERNAME)/.fonts/
	fc-cache -vf

services:
	@echo "Enabling wireplumber audio service for user $(USERNAME)..."
	$(SUDO) -u $(USERNAME) systemctl --user enable wireplumber.service || true
	$(SUDO) apt autoremove -y

flatpak:
	@echo "Setting up Flatpak and installing apps: $(FLATPAK_APPS)"
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak install -y --system $(FLATPAK_APPS)

gnome-extensions:
	@echo "Installing and enabling GNOME extensions: $(GNOME_EXTENSIONS)"
	@for ext in $(GNOME_EXTENSIONS); do \
		echo "Installing $$ext"; \
		gnome-extensions install --force "$$ext.zip" || true; \
		gnome-extensions enable "$$ext" || true; \
	done

gnome-settings:
	@echo "Setting GNOME desktop settings..."
	cp bg/bg.jpg /home/$(USERNAME)/Pictures/bg/
	gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/$(USERNAME)/Pictures/bg/bg.jpg"
	dconf load / < gnome/gnome-settings.ini || true
	gsettings set org.gnome.shell favorite-apps "['thunar.desktop', 'kitty.desktop', 'chromium.desktop', 'brave-browser.desktop']"
	gsettings set org.gnome.desktop.interface enable-animations false

docker-setup:
	@echo "Setting up Docker user permissions"
	$(SUDO) usermod -aG docker $(USERNAME)
	$(SUDO) systemctl restart docker

reboot:
	@echo "System setup complete! Rebooting now..."
	$(SUDO) systemctl reboot
