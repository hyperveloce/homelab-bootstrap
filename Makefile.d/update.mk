# Determine machine-specific config
CONFIG ?= $(shell hostname)
CONFIG_FILE := configs/$(CONFIG).config

# Load the config file if it exists
ifeq ("$(wildcard $(CONFIG_FILE))","")
$(warning No config file found at $(CONFIG_FILE). Using defaults.)
else
$(info Using config file: $(CONFIG_FILE))
endif

-include $(CONFIG_FILE)

# Default target
.PHONY: all update apt flatpak firmware pip npm custom print-config

all: update

# Print config values for verification
print-config:
	@echo "Using config: $(CONFIG_FILE)"
	@echo "ENABLE_FLATPAK = $(ENABLE_FLATPAK)"
	@echo "ENABLE_FWUPD   = $(ENABLE_FWUPD)"
	@echo "ENABLE_PIP     = $(ENABLE_PIP)"
	@echo "ENABLE_NPM     = $(ENABLE_NPM)"
	@echo "CUSTOM_COMMAND = $(CUSTOM_COMMAND)"


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
		echo -e "\n\033[1;32mRepairing Flatpak installation...\033[0m"; \
		flatpak repair; \
		echo -e "\n\033[1;32mRemoving unused Flatpak runtimes...\033[0m"; \
		flatpak uninstall --unused -y; \
		echo -e "\n\033[1;32mUpdating Flatpak applications and runtimes...\033[0m"; \
		flatpak update -y; \
	else \
		echo "Flatpak skipped."; \
	fi


firmware:
	@echo -e "\n\033[1;32mChecking for firmware updates...\033[0m"
	@if command -v fwupdmgr > /dev/null; then \
		sudo fwupdmgr refresh --force; \
		sudo fwupdmgr update; \
	else \
		echo "fwupd (firmware updater) not installed. Skipping."; \
	fi

pip:
	@if [ "$(ENABLE_PIP)" != "false" ] && command -v pip >/dev/null 2>&1; then \
		echo -e "\n\033[1;32mChecking outdated Python packages...\033[0m"; \
		pip list --outdated; \
	else \
		echo "pip check skipped."; \
	fi

npm:
	@echo -e "\n\033[1;32mChecking for outdated global npm packages...\033[0m"
	@if command -v npm > /dev/null; then \
		echo "npm global prefix is: $$(npm config get prefix)"; \
		npm outdated -g || true; \
		echo -e "\n\033[1;32mAttempting to update global npm packages...\033[0m"; \
		if npm config get prefix | grep -q "/usr"; then \
			echo "Detected system-wide npm prefix. Using sudo for update."; \
			sudo npm update -g; \
		else \
			echo "Detected user-local npm prefix. Updating without sudo."; \
			npm update -g; \
		fi; \
	else \
		echo "npm not found. Skipping."; \
	fi

npm_update:
	@echo -e "\n\033[1;32mUpdating global npm packages...\033[0m"
	@if command -v npm > /dev/null; then \
		if ! sudo npm update -g; then \
			echo "sudo failed, trying without sudo..."; \
			npm update -g || echo "Failed to update npm packages."; \
		fi; \
	else \
		echo "npm not found. Skipping."; \
	fi

custom:
	@echo -e "\n\033[1;32mRunning custom update steps...\033[0m"
	@bash -c '\
		if [ -n "$$CUSTOM_COMMAND" ]; then \
			echo "Running custom command: $$CUSTOM_COMMAND"; \
			eval "$$CUSTOM_COMMAND"; \
		elif [ -x "./custom-update.sh" ]; then \
			echo "Running ./custom-update.sh..."; \
			./custom-update.sh; \
		else \
			echo "No custom action configured."; \
		fi' \
		CUSTOM_COMMAND="$(CUSTOM_COMMAND)"
