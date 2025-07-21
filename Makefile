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

.PHONY: run-config
run-config:
run-config:
	@echo "🐳 Docker targets: $(MAKE_DOCKER_TARGETS)"
	@echo "🔄 Update targets: $(MAKE_UPDATE_TARGETS)"
	$(MAKE) -C bootstrap $(MAKE_DOCKER_TARGETS) $(MAKE_UPDATE_TARGETS)
