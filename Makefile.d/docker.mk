docker-update: docker-compose-update nextcloud-upgrade docker-clean

# Pull and recreate Docker Compose services
.PHONY: docker-compose-update
docker-compose-update:
	@if [ ! -f "$(DOCKER_COMPOSE_DIR)/docker-compose.yml" ]; then \
		echo "❌ docker-compose.yml not found in $(DOCKER_COMPOSE_DIR)"; \
		exit 1; \
	fi
	@echo "$$(date +'%Y-%m-%d %H:%M:%S') - 🚀 Starting Docker container updates..." | tee -a $(LOG_FILE)
	@cd $(DOCKER_COMPOSE_DIR) && docker-compose pull
	@cd $(DOCKER_COMPOSE_DIR) && docker-compose up -d --remove-orphans
	@echo "$$(date +'%Y-%m-%d %H:%M:%S') - ⏳ Waiting for services to initialize..." | tee -a $(LOG_FILE)
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
