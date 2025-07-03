# Determine machine-specific config
CONFIG ?= $(shell hostname)
CONFIG_FILE := configs/$(CONFIG).config

# Load the config file
ifeq ("$(wildcard $(CONFIG_FILE))","")
$(warning No config file found at $(CONFIG_FILE). Using defaults.)
endif

-include $(CONFIG_FILE)

# Default target
.PHONY: all update apt flatpak firmware pip npm custom print-config

all: update

update: apt flatpak firmware pip npm custom
	@echo -e "\n\033[1;32mSystem update completed!\033[0m"
	@echo "If the kernel or firmware was updated, consider rebooting."

apt:
	@echo -e "\n\033[1;32mUpdating APT packages...\033[0m"
	sudo apt update
	sudo apt upgrade -y
	sudo apt full-upgrade -y
	sudo apt autoremove -y
	sudo apt clean
	sudo apt autoclean

flatpak:
	@if [ "$(ENABLE_FLATPAK)" != "false" ] && command -v flatpak >/dev/null 2>&1; then \
		echo -e "\n\033[1;32mUpdating Flatpaks...\033[0m"; \
		flatpak update -y; \
	else \
		echo "Flatpak skipped."; \
	fi

firmware:
	@if [ "$(ENABLE_FWUPD)" != "false" ] && command -v fwupdmgr >/dev/null 2>&1; then \
		echo -e "\n\033[1;32mChecking firmware...\033[0m"; \
		sudo fwupdmgr refresh && sudo fwupdmgr update; \
	else \
		echo "Firmware update skipped."; \
	fi

pip:
	@if [ "$(ENABLE_PIP)" != "false" ] && command -v pip >/dev/null 2>&1; then \
		echo -e "\n\033[1;32mChecking outdated Python packages...\033[0m"; \
		pip list --outdated; \
	else \
		echo "pip check skipped."; \
	fi

npm:
	@if [ "$(ENABLE_NPM)" != "false" ] && command -v npm >/dev/null 2>&1; then \
		echo -e "\n\033[1;32mChecking outdated global npm packages...\033[0m"; \
		npm outdated -g; \
	else \
		echo "npm check skipped."; \
	fi

custom:
	@if [ -n "$(CUSTOM_COMMAND)" ]; then \
		echo -e "\n\033[1;32mRunning custom command...\033[0m"; \
		$(CUSTOM_COMMAND); \
	elif [ -x "./custom-update.sh" ]; then \
		./custom-update.sh; \
	else \
		echo "No custom action configured."; \
	fi

print-config:
	@echo "Using config: $(CONFIG_FILE)"
	@echo "ENABLE_FLATPAK = $(ENABLE_FLATPAK)"
	@echo "ENABLE_FWUPD   = $(ENABLE_FWUPD)"
	@echo "ENABLE_PIP     = $(ENABLE_PIP)"
	@echo "ENABLE_NPM     = $(ENABLE_NPM)"
	@echo "CUSTOM_COMMAND = $(CUSTOM_COMMAND)"
