#!/bin/sh

set -eu

echo "======================================"
echo "        Rebecca Panel v0.1.4"
echo "             Railway"
echo "======================================"

# --------------------------------------------------
# Directories
# --------------------------------------------------

mkdir -p /var/lib/rebecca
mkdir -p /var/lib/rebecca/certs
mkdir -p /var/lib/rebecca/config

# --------------------------------------------------
# Railway port
# --------------------------------------------------

PORT="${PORT:-8080}"

export PORT
export HOST="0.0.0.0"

export UVICORN_HOST="0.0.0.0"
export UVICORN_PORT="$PORT"

export REBECCA_GATEWAY_ADDR="0.0.0.0:${PORT}"

# --------------------------------------------------
# Database
# --------------------------------------------------

export DATABASE="sqlite:////var/lib/rebecca/rebecca.db"

# مهم:
# Runtime جدید Rebecca این متغیر را اجباری می‌خواهد.

export SQLALCHEMY_DATABASE_URL="sqlite:////var/lib/rebecca/rebecca.db"

export REBECCA_CONFIG_DIR="/var/lib/rebecca"
export REBECCA_CERT_BASE="/var/lib/rebecca/certs"

# Xray assets
export XRAY_LOCATION_ASSET="/usr/local/share/xray"

echo "[INFO] HOST=$HOST"
echo "[INFO] PORT=$PORT"
echo "[INFO] GATEWAY=$REBECCA_GATEWAY_ADDR"
echo "[INFO] DATABASE=$DATABASE"
echo "[INFO] SQLALCHEMY_DATABASE_URL=$SQLALCHEMY_DATABASE_URL"

# --------------------------------------------------
# Check binaries
# --------------------------------------------------

if [ ! -x /opt/rebecca/rebecca-cli ]; then
    echo "[ERROR] rebecca-cli not found"
    exit 1
fi

if [ ! -x /opt/rebecca/rebecca-server ]; then
    echo "[ERROR] rebecca-server not found"
    exit 1
fi

if [ ! -x /usr/local/bin/xray ]; then
    echo "[ERROR] Xray not found"
    exit 1
fi

echo "[INFO] rebecca-cli found"
echo "[INFO] rebecca-server found"
echo "[INFO] xray found"

# --------------------------------------------------
# Xray version
# --------------------------------------------------

echo "[INFO] Xray version:"
/usr/local/bin/xray version || true

# --------------------------------------------------
# Database migration
# --------------------------------------------------

echo "[INFO] Running database migrations..."

cd /opt/rebecca

/opt/rebecca/rebecca-cli migrate up

echo "[INFO] Database migration completed."

# --------------------------------------------------
# Create default admin
# --------------------------------------------------

echo "[INFO] Checking admin account..."

ADMIN_EXISTS=$(
    /opt/rebecca/rebecca-cli admin list 2>/dev/null \
    | awk '$2 == "admin" {print $2}' \
    | head -n 1
)

if [ "$ADMIN_EXISTS" = "admin" ]; then

    echo "[INFO] Admin 'admin' already exists."

else

    echo "[INFO] Creating default admin..."

    /opt/rebecca/rebecca-cli admin create admin \
        --password admin \
        --role full_access

    echo "[INFO] Admin 'admin' created successfully."

fi

# --------------------------------------------------
# Start Rebecca
# --------------------------------------------------

echo "======================================"
echo "        Starting Rebecca"
echo "======================================"

echo "[INFO] Listening on 0.0.0.0:${PORT}"
echo "[INFO] Railway PORT=${PORT}"

exec /opt/rebecca/rebecca-server