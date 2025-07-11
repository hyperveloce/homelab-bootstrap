.DEFAULT_GOAL := run-config

.PHONY: all
all: run-config

$(info Default goal is: $(.DEFAULT_GOAL))

CONFIG ?= $(shell hostname)
CONFIG_FILE := configs/$(CONFIG).config

ifeq ("$(wildcard $(CONFIG_FILE))","")
  $(warning No config file found at $(CONFIG_FILE). Using defaults.)
else
  $(info Using config file: $(CONFIG_FILE))
  include $(CONFIG_FILE)
endif

$(info MAKE_DOCKER_TARGETS = [$(MAKE_DOCKER_TARGETS)])
$(info MAKE_UPDATE_TARGETS = [$(MAKE_UPDATE_TARGETS)])

# === Include other Makefiles ===
include Makefile.d/docker.mk
include Makefile.d/update.mk
include Makefile.d/setup.mk

.PHONY: docker-compose-update nextcloud-upgrade docker-clean apt firmware pip custom

docker-compose-update:
	@$(MAKE) -C .. docker-compose-update

nextcloud-upgrade:
	@$(MAKE) -C .. nextcloud-upgrade

docker-clean:
	@$(MAKE) -C .. docker-clean

apt:
	@$(MAKE) -C .. apt

firmware:
	@$(MAKE) -C .. firmware

pip:
	@$(MAKE) -C .. pip

custom:
	@$(MAKE) -C .. custom

.PHONY: run-config
run-config:
	@echo "🐳 Running docker targets: $(MAKE_DOCKER_TARGETS)"
	@$(MAKE) -C $(CURDIR) $(MAKE_DOCKER_TARGETS)
	@echo "🛡️ Running update targets: $(MAKE_UPDATE_TARGETS)"
	@$(MAKE) -C bootstrap $(MAKE_UPDATE_TARGETS)


.PHONY: setup-run-config
setup-run-config:
	@echo "⚙️ Running setup targets: $(MAKE_SETUP_TARGETS)"
	@$(MAKE) $(MAKE_SETUP_TARGETS)
