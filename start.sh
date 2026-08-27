#!/bin/sh

set -eu

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
# Railway
# ============================================================

export HOST="0.0.0.0"
export PORT="${PORT:-8080}"

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

export XRAY_LOCATION_ASSET="/usr/local/share/xray"

export XRAY_PATH="/usr/local/bin/xray"
export XRAY_BINARY="/usr/local/bin/xray"
export XRAY_EXECUTABLE="/usr/local/bin/xray"

# ============================================================
# Information
# ============================================================

echo "[INFO] HOST=$HOST"
echo "[INFO] PORT=$PORT"
echo "[INFO] DATABASE=$DATABASE"
echo "[INFO] SQLALCHEMY_DATABASE_URL=$SQLALCHEMY_DATABASE_URL"

# ============================================================
# Check Xray
# ============================================================

echo "[INFO] Checking Xray..."

if [ ! -x /usr/local/bin/xray ]; then
    echo "[ERROR] Xray Core was not installed."
    exit 1
fi

echo "[INFO] Xray Core found:"
/usr/local/bin/xray version

# ============================================================
# Check Rebecca
# ============================================================

if [ ! -x /opt/rebecca/rebecca-cli ]; then
    echo "[ERROR] rebecca-cli not found."
    exit 1
fi

if [ ! -x /opt/rebecca/rebecca-server ]; then
    echo "[ERROR] rebecca-server not found."
    exit 1
fi

echo "[INFO] rebecca-cli found"
echo "[INFO] rebecca-server found"

# ============================================================
# Database migration
# ============================================================

echo "[INFO] Running database migrations..."

cd /opt/rebecca

/opt/rebecca/rebecca-cli migrate up

echo "[INFO] Database migration completed."

# ============================================================
# Admin
# ============================================================

echo "[INFO] Checking admin account..."

if /opt/rebecca/rebecca-cli admin list 2>/dev/null \
    | awk '$2 == "admin" {found=1} END {exit !found}'
then

    echo "[INFO] Admin 'admin' already exists."

else

    echo "[INFO] Creating default admin..."

    /opt/rebecca/rebecca-cli admin create admin \
        --password admin \
        --role full_access

    echo "[INFO] Admin 'admin' created successfully."

fi

# ============================================================
# Final information
# ============================================================

echo "======================================"
echo "        Starting Rebecca"
echo "======================================"

echo "[INFO] Rebecca: /opt/rebecca/rebecca-server"
echo "[INFO] Xray:    /usr/local/bin/xray"
echo "[INFO] PORT:     ${PORT}"
echo "[INFO] Listening on 0.0.0.0:${PORT}"

# ============================================================
# Start Rebecca
# ============================================================

exec /opt/rebecca/rebecca-server