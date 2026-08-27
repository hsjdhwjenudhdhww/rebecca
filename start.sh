#!/bin/bash

set -e

echo "======================================"
echo "        Rebecca Panel v0.1.4"
echo "             Railway"
echo "======================================"

# ============================================================
# Directories
# ============================================================

mkdir -p /var/lib/rebecca
mkdir -p /var/lib/rebecca/certs
mkdir -p /var/lib/rebecca/config

# ============================================================
# Railway port
# ============================================================

export HOST="0.0.0.0"
export PORT="${PORT:-8080}"

export UVICORN_HOST="0.0.0.0"
export UVICORN_PORT="$PORT"

export REBECCA_GATEWAY_ADDR="0.0.0.0:${PORT}"

# ============================================================
# Database
# ============================================================

export DATABASE="sqlite:////var/lib/rebecca/rebecca.db"

export SQLALCHEMY_DATABASE_URL="sqlite:////var/lib/rebecca/rebecca.db"

export REBECCA_CONFIG_DIR="/var/lib/rebecca"
export REBECCA_CERT_BASE="/var/lib/rebecca/certs"

# ============================================================
# Xray
# ============================================================

export XRAY_EXECUTABLE_PATH="/usr/local/bin/xray"
export XRAY_ASSETS_PATH="/usr/local/share/xray"

export XRAY_LOCATION_ASSET="/usr/local/share/xray"

# ============================================================
# Info
# ============================================================

echo "[INFO] HOST=$HOST"
echo "[INFO] PORT=$PORT"
echo "[INFO] GATEWAY=$REBECCA_GATEWAY_ADDR"
echo "[INFO] DATABASE=$DATABASE"
echo "[INFO] SQLALCHEMY_DATABASE_URL=$SQLALCHEMY_DATABASE_URL"

# ============================================================
# Check Xray
# ============================================================

echo "[INFO] Checking Xray..."

if [ ! -x /usr/local/bin/xray ]; then
    echo "[ERROR] Xray Core is not installed."
    exit 1
fi

echo "[INFO] Xray Core found:"
/usr/local/bin/xray version

# ============================================================
# Find Rebecca
# ============================================================

REBECCA=""

if [ -x /usr/local/bin/rebecca ]; then
    REBECCA="/usr/local/bin/rebecca"
elif [ -x /opt/rebecca/rebecca ]; then
    REBECCA="/opt/rebecca/rebecca"
elif [ -x /opt/rebecca/rebecca-cli ]; then
    REBECCA="/opt/rebecca/rebecca-cli"
fi

if [ -z "$REBECCA" ]; then
    echo "[ERROR] Rebecca CLI not found."

    echo "[INFO] Searching..."
    find /opt/rebecca /usr/local/bin \
        -maxdepth 3 \
        -type f \
        -name '*rebecca*' \
        -ls || true

    exit 1
fi

echo "[INFO] Rebecca CLI: $REBECCA"

# ============================================================
# Find Rebecca server
# ============================================================

SERVER=""

if [ -x /opt/rebecca/rebecca-server ]; then
    SERVER="/opt/rebecca/rebecca-server"
elif [ -x /usr/local/bin/rebecca-server ]; then
    SERVER="/usr/local/bin/rebecca-server"
elif [ -x /opt/rebecca/dist/rebecca-server ]; then
    SERVER="/opt/rebecca/dist/rebecca-server"
fi

if [ -z "$SERVER" ]; then
    echo "[ERROR] Rebecca server not found."

    find /opt/rebecca /usr/local/bin \
        -maxdepth 4 \
        -type f \
        -name '*rebecca*' \
        -ls || true

    exit 1
fi

echo "[INFO] Rebecca server: $SERVER"

# ============================================================
# Database migration
# ============================================================

echo "[INFO] Running database migrations..."

cd /opt/rebecca

"$REBECCA" migrate up

echo "[INFO] Database migration completed."

# ============================================================
# Admin
# ============================================================

echo "[INFO] Checking admin account..."

if "$REBECCA" admin list 2>/dev/null \
    | awk '$2 == "admin" { found=1 } END { exit !found }'
then

    echo "[INFO] Admin 'admin' already exists."

else

    echo "[INFO] Creating default admin..."

    "$REBECCA" admin create admin \
        --password admin \
        --role full_access

    echo "[INFO] Admin 'admin' created successfully."

fi

# ============================================================
# Start
# ============================================================

echo "======================================"
echo "        Starting Rebecca"
echo "======================================"

echo "[INFO] Listening on 0.0.0.0:${PORT}"
echo "[INFO] Railway PORT=${PORT}"
echo "[INFO] Xray=/usr/local/bin/xray"

exec "$SERVER"