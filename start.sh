#!/bin/sh
set -eu

echo "======================================"
echo "        Rebecca Panel v0.1.4"
echo "             Railway"
echo "======================================"

HOST="0.0.0.0"
PORT="8080"
DATABASE="sqlite:////var/lib/rebecca/rebecca.db"

export HOST
export PORT
export DATABASE

mkdir -p /var/lib/rebecca

cd /opt/rebecca

echo "[INFO] HOST=$HOST"
echo "[INFO] PORT=$PORT"
echo "[INFO] DATABASE=$DATABASE"

# Check files
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

# ======================================
# Database migration
# ======================================

echo "[INFO] Running database migrations..."

/opt/rebecca/rebecca-cli migrate up

echo "[INFO] Database migration completed."

# ======================================
# Admin
# ======================================

echo "[INFO] Checking admin account..."

if /opt/rebecca/rebecca-cli admin show admin >/dev/null 2>&1; then
    echo "[INFO] Admin 'admin' already exists."
else
    echo "[INFO] Creating default admin..."

    /opt/rebecca/rebecca-cli admin create admin \
        --password admin \
        --role full_access

    echo "[INFO] Admin 'admin' created successfully."
fi

# ======================================
# Start
# ======================================

echo "======================================"
echo "        Starting Rebecca"
echo "======================================"

echo "[INFO] Listening on 0.0.0.0:8080"
echo "[INFO] Railway PORT=8080"

exec /opt/rebecca/rebecca-server
