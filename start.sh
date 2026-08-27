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
    echo "[WARN] Continuing startup..."
fi

# ======================================
# Create admin automatically
# ======================================

echo "[INFO] Checking admin account..."

ADMIN_USERNAME="admin"
ADMIN_PASSWORD="admin"

# Try to create the full-access admin.
# Username/password are supplied through stdin so Railway
# does not require interactive input.

printf '%s\n%s\n' "$ADMIN_USERNAME" "$ADMIN_PASSWORD" | \
    /opt/rebecca/dist/rebecca-cli cli admin create --role full_access \
    || echo "[INFO] Admin may already exist or CLI rejected duplicate account."

echo "[INFO] Admin setup completed."

# ======================================
# Start Rebecca
# ======================================

echo "[INFO] Starting Rebecca server..."

exec /opt/rebecca/dist/rebecca-server