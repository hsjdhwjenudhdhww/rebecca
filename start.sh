#!/bin/sh
set -eu

echo "======================================"
echo "        Rebecca Panel v0.1.4"
echo "             Railway"
echo "======================================"

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8080}"
GATEWAY="${GATEWAY:-${HOST}:${PORT}}"

DATA_DIR="${DATA_DIR:-/var/lib/rebecca}"
DATABASE="${DATABASE:-sqlite:///${DATA_DIR}/rebecca.db}"

export HOST
export PORT
export GATEWAY
export DATABASE

mkdir -p "$DATA_DIR"

echo "[INFO] PORT=$PORT"
echo "[INFO] HOST=$HOST"
echo "[INFO] GATEWAY=$GATEWAY"
echo "[INFO] DATABASE=$DATABASE"

cd /opt/rebecca

if [ ! -x /opt/rebecca/rebecca-cli ]; then
    echo "[ERROR] rebecca-cli not found"
    exit 1
fi

if [ ! -x /opt/rebecca/rebecca-server ]; then
    echo "[ERROR] rebecca-server not found"
    exit 1
fi

echo "[INFO] rebecca-cli found"
echo "[INFO] rebecca-server found"

# --------------------------------------
# Database migration
# --------------------------------------

echo "[INFO] Running Rebecca database migrations..."

/opt/rebecca/rebecca-cli migrate

echo "[INFO] Database migration completed."

# --------------------------------------
# Admin creation
# --------------------------------------

ADMIN_USERNAME="${ADMIN_USERNAME:-}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
ADMIN_ROLE="${ADMIN_ROLE:-full_access}"

if [ -n "$ADMIN_USERNAME" ] && [ -n "$ADMIN_PASSWORD" ]; then

    echo "[INFO] Checking admin account..."

    if /opt/rebecca/rebecca-cli admin show "$ADMIN_USERNAME" >/dev/null 2>&1; then
        echo "[INFO] Admin '$ADMIN_USERNAME' already exists."
    else
        echo "[INFO] Creating admin '$ADMIN_USERNAME'..."

        /opt/rebecca/rebecca-cli admin create \
            "$ADMIN_USERNAME" \
            --password "$ADMIN_PASSWORD" \
            --role "$ADMIN_ROLE"

        echo "[INFO] Admin '$ADMIN_USERNAME' created."
    fi

else
    echo "[INFO] No admin environment variables supplied."
    echo "[INFO] Skipping automatic admin creation."
fi

# --------------------------------------
# Start Rebecca
# --------------------------------------

echo "======================================"
echo "        Starting Rebecca"
echo "======================================"

echo "[INFO] Listening on ${HOST}:${PORT}"
echo "[INFO] Railway PORT=${PORT}"

exec /opt/rebecca/rebecca-server
