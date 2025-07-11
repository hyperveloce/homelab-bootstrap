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

.PHONY: run-config
run-config:
	@echo "🐳 Running docker targets: $(MAKE_DOCKER_TARGETS)"
	@$(MAKE) $(MAKE_DOCKER_TARGETS)
	@echo "🛡️ Running update targets: $(MAKE_UPDATE_TARGETS)"
	@$(MAKE) $(MAKE_UPDATE_TARGETS)

.PHONY: setup-run-config
setup-run-config:
	@echo "⚙️ Running setup targets: $(MAKE_SETUP_TARGETS)"
	@$(MAKE) $(MAKE_SETUP_TARGETS)
