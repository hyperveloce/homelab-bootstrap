.DEFAULT_GOAL := update-run-config

CONFIG ?= $(shell hostname)
CONFIG_FILE := configs/$(CONFIG).config

ifeq ("$(wildcard $(CONFIG_FILE))","")
$(warning No config file found at $(CONFIG_FILE). Using defaults.)
else
$(info Using config file: $(CONFIG_FILE))
include $(CONFIG_FILE)
endif

.PHONY: update-run-config
update-run-config:
	@echo "📦 Running update targets: $(MAKE_UPDATE_TARGETS)"
	@$(MAKE) $(MAKE_UPDATE_TARGETS)

.PHONY: all update apt flatpak firmware pip npm custom print-config

all: update

print-config:
	@echo "Using config: $(CONFIG_FILE)"
	@echo "ENABLE_FLATPAK = $(ENABLE_FLATPAK)"
	@echo "ENABLE_FWUPD   = $(ENABLE_FWUPD)"
	@echo "ENABLE_PIP     = $(ENABLE_PIP)"
	@echo "ENABLE_NPM     = $(ENABLE_NPM)"
	@echo "CUSTOM_COMMAND = $(CUSTOM_COMMAND)"

update:
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
	@echo -e "\n\033[1;32mRepairing Flatpak installation...\033[0m"
	flatpak repair
	@echo -e "\n\033[1;32mRemoving unused Flatpak runtimes...\033[0m"
	flatpak uninstall --unused -y
	@echo -e "\n\033[1;32mUpdating Flatpak applications and runtimes...\033[0m"
	flatpak update -y

firmware:
	@echo -e "\n\033[1;32mChecking for firmware updates...\033[0m"
	sudo fwupdmgr refresh --force
	sudo fwupdmgr update

pip:
	@echo -e "\n\033[1;32mChecking outdated Python packages...\033[0m"
	pip list --outdated || true

npm:
	@echo -e "\n\033[1;32mChecking for outdated global npm packages...\033[0m"
	echo "npm global prefix is: $$(npm config get prefix)"
	npm outdated -g || true
	@echo -e "\n\033[1;32mAttempting to update global npm packages...\033[0m"
	if npm config get prefix | grep -q "/usr"; then \
		echo "Detected system-wide npm prefix. Using sudo for update."; \
		sudo npm update -g; \
	else \
		echo "Detected user-local npm prefix. Updating without sudo."; \
		npm update -g; \
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
