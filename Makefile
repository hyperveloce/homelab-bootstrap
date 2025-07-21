CONFIG ?= $(shell hostname)
CONFIG_FILE := configs/$(CONFIG).config

ifeq ("$(wildcard $(CONFIG_FILE))","")
  $(warning No config file found at $(CONFIG_FILE). Using defaults.)
else
  include $(CONFIG_FILE)
endif

# Export variables for sub-make
export MAKE_DOCKER_TARGETS
export MAKE_UPDATE_TARGETS

# === Include other Makefiles ===
include Makefile.d/docker.mk
include Makefile.d/update.mk

.DEFAULT_GOAL := run-config

.PHONY: run-config
run-config:
	@echo "🐳 make Docker targets: $(MAKE_DOCKER_TARGETS)"
	@echo "📦 make Update targets: $(MAKE_UPDATE_TARGETS)"
	$(MAKE) $(MAKE_DOCKER_TARGETS) $(MAKE_UPDATE_TARGETS)
