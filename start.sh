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
    echo "[WARN] Migration command returned an error."
fi

# ======================================
# Create admin automatically
# ======================================

echo "[INFO] Checking admin account..."

ADMIN_USERNAME="admin"
ADMIN_PASSWORD="admin"

if printf '%s\n%s\n' \
    "$ADMIN_USERNAME" \
    "$ADMIN_PASSWORD" \
    | /opt/rebecca/dist/rebecca-cli admin create --role full_access
then
    echo "[INFO] Admin account created successfully."
else
    echo "[INFO] Admin already exists or admin creation was rejected."
fi

# ======================================
# Start server
# ======================================

echo "[INFO] Starting Rebecca server..."

exec /opt/rebecca/dist/rebecca-server