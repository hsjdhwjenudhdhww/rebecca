#!/bin/bash
set -e

echo "======================================"
echo "        Rebecca Panel v0.1.4"
echo "             Railway"
echo "======================================"

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-1234}"

export HOST
export PORT

export DATABASE="${DATABASE:-sqlite:////var/lib/rebecca/rebecca.db}"
export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

mkdir -p /var/lib/rebecca
mkdir -p /opt/rebecca

echo "[INFO] HOST=$HOST"
echo "[INFO] PORT=$PORT"
echo "[INFO] DATABASE=$DATABASE"
echo "[INFO] SQLALCHEMY_DATABASE_URL=$SQLALCHEMY_DATABASE_URL"

# --------------------------------------------------
# Xray
# --------------------------------------------------

if command -v xray >/dev/null 2>&1; then
    echo "[INFO] Xray Core found"
    xray version || true
else
    echo "[ERROR] Xray Core not found"
    exit 1
fi

# --------------------------------------------------
# Rebecca binaries
# --------------------------------------------------

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

export PATH="/opt/rebecca:$PATH"

# --------------------------------------------------
# Database migration
# --------------------------------------------------

echo "[INFO] Checking database..."

if /opt/rebecca/rebecca-cli migrate up; then
    echo "[INFO] Database migration completed"
else
    echo "[ERROR] Database migration failed"
    exit 1
fi

# --------------------------------------------------
# Admin
# --------------------------------------------------

echo "[INFO] Checking admin account..."

if [ -n "${ADMIN_USERNAME:-}" ] && [ -n "${ADMIN_PASSWORD:-}" ]; then

    echo "[INFO] Admin credentials supplied by environment"

    # فقط اطلاع‌رسانی؛ CLI فعلی interactive است
    # و نباید در Railway بدون stdin اجرا شود.
    echo "[INFO] ADMIN_USERNAME=$ADMIN_USERNAME"

else
    echo "[INFO] ADMIN_USERNAME / ADMIN_PASSWORD not configured"
    echo "[INFO] Skipping automatic interactive admin creation"
fi

# --------------------------------------------------
# Start Rebecca
# --------------------------------------------------

echo "[INFO] Starting Rebecca server..."

exec /opt/rebecca/rebecca-server
