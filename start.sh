#!/bin/sh

set -eu

echo "======================================"
echo "        Rebecca Panel - Railway       "
echo "======================================"

PORT="${PORT:-8080}"

export UVICORN_HOST="0.0.0.0"
export UVICORN_PORT="$PORT"

export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

mkdir -p /var/lib/rebecca

echo "[INFO] Listening on 0.0.0.0:${PORT}"
echo "[INFO] Database: ${SQLALCHEMY_DATABASE_URL}"

# ======================================
# Database migration
# ======================================

echo "[INFO] Running database migrations..."

if /opt/rebecca/dist/rebecca-cli migrate up; then
    echo "[INFO] Database migration completed."
else
    echo "[WARN] Migration failed."
fi

# ======================================
# Create admin automatically
# ======================================

echo "[INFO] Creating admin account..."

ADMIN_USER="admin"
ADMIN_PASS="admin"

if command -v script >/dev/null 2>&1; then

    printf '%s\n%s\n%s\n' \
        "$ADMIN_USER" \
        "$ADMIN_PASS" \
        "$ADMIN_PASS" \
        | script -qec "/opt/rebecca/dist/rebecca-cli admin create --role full_access" /dev/null \
        && echo "[INFO] Admin creation completed." \
        || echo "[INFO] Admin may already exist."

else

    echo "[WARN] 'script' command is not available."
    echo "[WARN] Admin creation skipped."

fi

# ======================================
# Start Rebecca
# ======================================

echo "[INFO] Starting Rebecca server..."

exec /opt/rebecca/dist/rebecca-server
#amirspider