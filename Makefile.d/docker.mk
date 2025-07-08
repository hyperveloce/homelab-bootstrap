docker-update: docker-check docker-compose-update nextcloud-upgrade docker-clean

# Check for Docker + container existence
.PHONY: docker-check
docker-check:
	@sh -c '\
		if ! command -v docker >/dev/null 2>&1; then \
			echo "⚠️ Docker not installed. Skipping docker-update."; \
			exit 0; \
		fi \
	'

	@sh -c '\
		if ! docker info >/dev/null 2>&1; then \
			echo "⚠️ Docker daemon not running. Skipping docker-update."; \
			exit 0; \
		fi \
	'

	@sh -c '\
		if ! docker ps -a --format "{{.Names}}" | grep -q "^$(NEXTCLOUD_CONTAINER)$$"; then \
			echo "⚠️ Nextcloud container '\''$(NEXTCLOUD_CONTAINER)'\'' not found. Skipping Nextcloud upgrade."; \
			exit 0; \
		fi \
	'


# Pull and recreate Docker Compose services
.PHONY: docker-compose-update
docker-compose-update:
	@if [ ! -f "$(DOCKER_COMPOSE_DIR)/docker-compose.yml" ]; then \
		echo "❌ docker-compose.yml not found in $(DOCKER_COMPOSE_DIR)"; \
		exit 1; \
	fi
	@cd $(DOCKER_COMPOSE_DIR) || { echo "❌ Failed to cd to $(DOCKER_COMPOSE_DIR)"; exit 1; }
	@echo "$$(date +'%Y-%m-%d %H:%M:%S') - 🚀 Starting Docker container updates..." | tee -a $(LOG_FILE)
	@docker-compose pull
	@docker-compose up -d --remove-orphans
	@echo "$$(date +'%Y-%m-%d %H:%M:%S') - ⏳ Waiting for Nextcloud to initialize..." | tee -a $(LOG_FILE)
	@sleep 10


# Nextcloud upgrade & maintenance
.PHONY: nextcloud-upgrade
nextcloud-upgrade:
	@if [ "$(SKIP_NEXTCLOUD)" != "true" ]; then \
		echo "$$(date +'%Y-%m-%d %H:%M:%S') - ⚙️ Running Nextcloud upgrade..." | tee -a $(LOG_FILE); \
		docker exec -u www-data $(NEXTCLOUD_CONTAINER) php occ upgrade 2>&1 | tee -a $(LOG_FILE); \
		echo "$$(date +'%Y-%m-%d %H:%M:%S') - 🛠️ Running maintenance:repair..." | tee -a $(LOG_FILE); \
		docker exec -u www-data $(NEXTCLOUD_CONTAINER) php occ maintenance:repair 2>&1 | tee -a $(LOG_FILE); \
		echo "$$(date +'%Y-%m-%d %H:%M:%S') - ✅ Disabling maintenance mode..." | tee -a $(LOG_FILE); \
		docker exec -u www-data $(NEXTCLOUD_CONTAINER) php occ maintenance:mode --off 2>&1 | tee -a $(LOG_FILE); \
	else \
		echo "⚠️ Skipping Nextcloud upgrade and maintenance as container not found."; \
	fi

# Docker cleanup
.PHONY: docker-clean
docker-clean:
	@echo "$$(date +'%Y-%m-%d %H:%M:%S') - 🧹 Cleaning up Docker system..." | tee -a $(LOG_FILE)
	@docker system prune -f
	@docker image prune -f
	@docker network prune -f
	@echo "$$(date +'%Y-%m-%d %H:%M:%S') - 🎉 Docker update process completed." | tee -a $(LOG_FILE)
