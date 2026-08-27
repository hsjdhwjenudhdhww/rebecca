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

/opt/rebecca/dist/rebecca-cli migrate up

echo "[INFO] Database migration completed."

# ======================================
# Create admin
# ======================================

echo "[INFO] Checking admin account..."

(
    printf 'admin\n'
    printf 'admin\n'
    printf 'admin\n'
) | /opt/rebecca/dist/rebecca-cli admin create --role full_access \
    && echo "[INFO] Admin account created." \
    || echo "[INFO] Admin already exists or creation failed."

# ======================================
# Start Rebecca
# ======================================

echo "[INFO] Starting Rebecca server..."

exec /opt/rebecca/dist/rebecca-server