#!/bin/bash

set -u

echo "======================================"
echo "        Rebecca Panel v0.1.4"
echo "             Railway"
echo "======================================"

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-1234}"

export HOST
export PORT

export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

mkdir -p /var/lib/rebecca

echo "[INFO] HOST=$HOST"
echo "[INFO] PORT=$PORT"
echo "[INFO] DATABASE=$SQLALCHEMY_DATABASE_URL"

# =========================
# Xray
# =========================

if command -v xray >/dev/null 2>&1; then
    echo "[INFO] Xray Core found"
    xray version || true
else
    echo "[ERROR] Xray Core not found"
    exit 1
fi

# =========================
# Rebecca binaries
# =========================

if [ -x /opt/rebecca/rebecca-cli ]; then
    echo "[INFO] rebecca-cli found"
else
    echo "[ERROR] rebecca-cli not found"
    exit 1
fi

if [ -x /opt/rebecca/rebecca-server ]; then
    echo "[INFO] rebecca-server found"
else
    echo "[ERROR] rebecca-server not found"
    exit 1
fi

# =========================
# Database
# =========================

echo "[INFO] Checking database..."

if /opt/rebecca/rebecca-cli migrate up; then
    echo "[INFO] Database migration completed"
else
    echo "[ERROR] Database migration failed"
    exit 1
fi

# =========================
# Admin
# =========================

echo "[INFO] Checking admin account..."

ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"

if [ -n "$ADMIN_PASSWORD" ]; then

    echo "[INFO] Admin username: $ADMIN_USERNAME"

    /opt/rebecca/rebecca-cli admin create \
        --username "$ADMIN_USERNAME" \
        --password "$ADMIN_PASSWORD" \
        --role full_access \
        || echo "[WARN] Admin may already exist or CLI options differ."

else

    echo "[WARN] ADMIN_PASSWORD is not set."
    echo "[WARN] Skipping automatic admin creation."

fi

# =========================
# Start server
# =========================

echo "======================================"
echo "[INFO] Starting Rebecca server"
echo "[INFO] Listening on $HOST:$PORT"
echo "======================================"

exec /opt/rebecca/rebecca-server
