.DEFAULT_GOAL := run-config

CONFIG ?= $(shell hostname)
CONFIG_FILE := configs/$(CONFIG).config

ifeq ("$(wildcard $(CONFIG_FILE))","")
$(warning No config file found at $(CONFIG_FILE). Using defaults.)
else
$(info Using config file: $(CONFIG_FILE))
include $(CONFIG_FILE)
endif

include Makefile.d/docker.mk
include Makefile.d/update.mk

# === Full run (default) ===
.PHONY: run-config
run-config:
	@echo "🐳 Running docker targets: $(MAKE_DOCKER_TARGETS)"
	@$(MAKE) $(MAKE_DOCKER_TARGETS)
	@echo "🛡️ Running update targets: $(MAKE_UPDATE_TARGETS)"
	@$(MAKE) $(MAKE_UPDATE_TARGETS)

# === Docker-only ===
.PHONY: docker-run-config
docker-run-config:
	@echo "🐳 Running docker targets: $(MAKE_DOCKER_TARGETS)"
	@$(MAKE) $(MAKE_DOCKER_TARGETS)

# === Update-only ===
.PHONY: update-run-config
update-run-config:
	@echo "🛡️ Running update targets: $(MAKE_UPDATE_TARGETS)"
	@$(MAKE) $(MAKE_UPDATE_TARGETS)
