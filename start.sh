#!/bin/sh

set -eu

echo "======================================"
echo "        Rebecca Panel v0.1.4          "
echo "             Railway                  "
echo "======================================"

PORT="${PORT:-8080}"

export UVICORN_HOST="0.0.0.0"
export UVICORN_PORT="8080"
export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

mkdir -p /var/lib/rebecca

DB_PATH="/var/lib/rebecca/rebecca.db"

echo "[INFO] Checking GLIBC..."
ldd --version | head -n 1

echo "[INFO] PORT=${PORT}"
echo "[INFO] DATABASE=${SQLALCHEMY_DATABASE_URL}"

# ======================================
# SQLite configuration
# ======================================

if [ -f "$DB_PATH" ]; then
    echo "[INFO] Configuring SQLite..."

    sqlite3 "$DB_PATH" <<'SQL'
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA busy_timeout=60000;
PRAGMA wal_autocheckpoint=1000;
SQL

    echo "[INFO] SQLite configured."
fi

# ======================================
# Create admin
# ======================================

echo "[INFO] Creating admin account..."

if /opt/rebecca/rebecca-cli admin create \
    --username admin \
    --password admin \
    --role full_access
then
    echo "[INFO] Admin account created successfully."
else
    echo "[INFO] Admin already exists or creation was rejected."
fi

# ======================================
# Start Rebecca
# ======================================

echo "[INFO] Starting Rebecca server..."

exec /opt/rebecca/rebecca-server
