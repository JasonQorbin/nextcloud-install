#!/usr/bin/env bash
set -euo pipefail

# Configuration
VPS_USER="user"
VPS_HOST="cloud.jasonpieterse.co.za"
VPS_KEY="~/.ssh/vps_backup_key"
COMPOSE_PATH="/path/to/vps/docker-compose.yml"

# Home Server Borg Repo
BORG_REPO="/mnt/storage/backups/nextcloud-borg"
export BORG_PASSPHRASE="your-secure-repository-passphrase"

# Helper function for remote SSH execution
vps_exec() {
    ssh -i "${VPS_KEY}" "${VPS_USER}@${VPS_HOST}" "$1"
}

# Trap hook: Guaranteed to turn maintenance mode off even if Borg errors out
cleanup() {
    echo "==> Restoring Nextcloud operational state (disabling maintenance mode)..."
    vps_exec "docker compose -f ${COMPOSE_PATH} exec -T nextcloud php occ maintenance:mode --off" || true
}
trap cleanup EXIT

echo "==> [1/5] Enabling Nextcloud maintenance mode..."
vps_exec "docker compose -f ${COMPOSE_PATH} exec -T nextcloud php occ maintenance:mode --on"

echo "==> [2/5] Dumping MariaDB database on VPS..."
vps_exec "docker compose -f ${COMPOSE_PATH} exec -T db mariadb-dump -u root -p'\${DB_ROOT_PASSWORD}' \${NC_DB_NAME} > /var/lib/docker/volumes/nextcloud-user-data/_data/nextcloud_db_dump.sql"

echo "==> [3/5] Pulling snapshot into Borg Repository..."
# Borg pulls directly over SSH from the home server
borg create \
    --stats \
    --progress \
    --compression zstd,3 \
    --remote-path /usr/bin/borg \
    ssh://${VPS_USER}@${VPS_HOST}:${VPS_KEY}#${BORG_REPO}::{now:%Y-%m-%d_%H:%M} \
    /var/lib/docker/volumes/nextcloud-user-data/_data \
    /path/to/vps/config/files

echo "==> [4/5] Cleaning up temporary SQL dump on VPS..."
vps_exec "rm -f /var/lib/docker/volumes/nextcloud-user-data/_data/nextcloud_db_dump.sql"

echo "==> [5/5] Pruning old Borg archives per retention policy..."
borg prune \
    --list \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 12 \
    "${BORG_REPO}"

echo "==> Backup and Prune completed successfully!"
