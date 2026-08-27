#!/bin/sh

set -e

echo "======================================"
echo "        Rebecca Panel v0.1.4"
echo "             Railway"
echo "======================================"

export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-8080}"
export GATEWAY="${GATEWAY:-0.0.0.0:${PORT}}"
export DATABASE="${DATABASE:-sqlite:////var/lib/rebecca/rebecca.db}"

mkdir -p /var/lib/rebecca

echo "[INFO] HOST=$HOST"
echo "[INFO] PORT=$PORT"
echo "[INFO] GATEWAY=$GATEWAY"
echo "[INFO] DATABASE=$DATABASE"

# ==========================================
# Check Xray
# ==========================================

if [ -x /usr/local/bin/xray ]; then
    echo "[INFO] Xray found:"
    /usr/local/bin/xray version
else
    echo "[ERROR] Xray Core not found!"
    exit 1
fi

# ==========================================
# Check Rebecca
# ==========================================

if [ -x /opt/rebecca/rebecca-cli ]; then
    echo "[INFO] rebecca-cli found"
else
    echo "[ERROR] rebecca-cli not found!"
    exit 1
fi

if [ -x /opt/rebecca/rebecca-server ]; then
    echo "[INFO] rebecca-server found"
else
    echo "[ERROR] rebecca-server not found!"
    exit 1
fi

# ==========================================
# Database migration
# ==========================================

echo "[INFO] Running database migrations..."

cd /opt/rebecca

/opt/rebecca/rebecca-cli migrate up

echo "[INFO] Database migration completed."

# ==========================================
# Admin
# ==========================================

echo "[INFO] Checking admin account..."

if /opt/rebecca/rebecca-cli admin list 2>/dev/null | \
    awk '{print $2}' | grep -qx "admin"; then

    echo "[INFO] Admin 'admin' already exists."

else

    echo "[INFO] Creating default admin..."

    /opt/rebecca/rebecca-cli admin create admin \
        --password admin \
        --role full_access

    echo "[INFO] Admin 'admin' created successfully."

fi

# ==========================================
# Start Rebecca
# ==========================================

echo "======================================"
echo "        Starting Rebecca"
echo "======================================"

echo "[INFO] Listening on ${HOST}:${PORT}"
echo "[INFO] Railway PORT=${PORT}"

exec /opt/rebecca/rebecca-server