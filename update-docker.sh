#!/bin/bash
# chmod +x update-docker.sh

# Set the path to your Docker Compose files
DOCKER_COMPOSE_DIR="/home/kanasu/git.hyperveloce/kserver"
LOG_FILE="/var/log/docker_update.log"
NEXTCLOUD_CONTAINER="nextcloud"

# Timestamp function
timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Logging function
log() {
    echo "$(timestamp) - $1" | tee -a "$LOG_FILE"
}

# Navigate to the Docker Compose directory
cd "$DOCKER_COMPOSE_DIR" || { log "❌ Failed to navigate to $DOCKER_COMPOSE_DIR"; exit 1; }

log "🚀 Starting Docker container updates..."

# Pull the latest images
log "📥 Pulling the latest images..."
docker-compose pull

# Recreate containers with updated images
log "🔄 Recreating containers..."
docker-compose up -d --remove-orphans

# Wait for Nextcloud to initialize (adjust sleep if needed)
log "⏳ Waiting a few seconds for Nextcloud to initialize..."
sleep 10

# Run Nextcloud upgrade
log "⚙️ Running Nextcloud upgrade..."
docker exec -u www-data "$NEXTCLOUD_CONTAINER" php occ upgrade || log "⚠️ occ upgrade failed"

# Run maintenance:repair
log "🛠️ Running Nextcloud maintenance:repair..."
docker exec -u www-data "$NEXTCLOUD_CONTAINER" php occ maintenance:repair || log "⚠️ maintenance:repair returned warnings"

# Ensure maintenance mode is off
log "✅ Disabling maintenance mode..."
docker exec -u www-data "$NEXTCLOUD_CONTAINER" php occ maintenance:mode --off || log "⚠️ Failed to disable maintenance mode"

# Cleanup
log "🧹 Cleaning up old images and containers..."
docker system prune -f
docker image prune -f
docker network prune -f

log "🎉 Docker update and Nextcloud upgrade completed."

exit 0
