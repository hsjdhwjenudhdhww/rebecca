#!/bin/bash
set -e

echo "======================================"
echo "        Rebecca Panel v0.1.4"
echo "             Railway"
echo "======================================"

export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-8080}"
export DATABASE="${DATABASE:-sqlite:////var/lib/rebecca/rebecca.db}"
export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-$DATABASE}"
export XRAY_LOCATION_ASSET="${XRAY_LOCATION_ASSET:-/usr/local/share/xray}"

mkdir -p /var/lib/rebecca

echo "[INFO] HOST=$HOST"
echo "[INFO] PORT=$PORT"
echo "[INFO] DATABASE=$DATABASE"
echo "[INFO] SQLALCHEMY_DATABASE_URL=$SQLALCHEMY_DATABASE_URL"

if [ -x /usr/local/bin/xray ]; then
    echo "[INFO] Xray Core found"
    /usr/local/bin/xray version
else
    echo "[ERROR] Xray Core not found"
    exit 1
fi

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

echo "[INFO] Checking admin account..."

if /opt/rebecca/rebecca-cli admin show admin >/dev/null 2>&1; then
    echo "[INFO] Admin 'admin' already exists."
else
    echo "[INFO] Creating default admin..."

    printf 'admin\nadmin\nadmin\n' | \
        /opt/rebecca/rebecca-cli admin create

    echo "[INFO] Default admin created."
fi

echo "======================================"
echo "        Starting Rebecca"
echo "======================================"

echo "[INFO] Listening on $HOST:$PORT"
echo "[INFO] Railway PORT=$PORT"

exec /opt/rebecca/rebecca-server