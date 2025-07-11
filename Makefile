CONFIG ?= $(shell hostname)
CONFIG_FILE := configs/$(CONFIG).config

ifeq ("$(wildcard $(CONFIG_FILE))","")
  $(warning No config file found at $(CONFIG_FILE). Using defaults.)
else
  include $(CONFIG_FILE)
endif

# === Include other Makefiles ===
include Makefile.d/docker.mk
include Makefile.d/update.mk
include Makefile.d/setup.mk

.PHONY: run-config
run-config:
	@echo "🐳 Running docker targets inside bootstrap directory: $(MAKE_DOCKER_TARGETS)"
	@$(MAKE) -C bootstrap $(MAKE_DOCKER_TARGETS)
	@echo "🛡️ Running update targets inside bootstrap directory: $(MAKE_UPDATE_TARGETS)"
	@$(MAKE) -C bootstrap $(MAKE_UPDATE_TARGETS)
