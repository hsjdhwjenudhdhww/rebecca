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

echo "[INFO] PORT=${PORT}"
echo "[INFO] DATABASE=${SQLALCHEMY_DATABASE_URL}"

# ======================================
# Locate Rebecca CLI
# ======================================

if [ -x "/opt/rebecca/rebecca-cli" ]; then
    CLI="/opt/rebecca/rebecca-cli"
elif [ -x "/opt/rebecca/dist/rebecca-cli" ]; then
    CLI="/opt/rebecca/dist/rebecca-cli"
else
    CLI="$(find /opt/rebecca -type f -name 'rebecca-cli' -print -quit)"
fi

if [ -z "${CLI:-}" ]; then
    echo "[ERROR] rebecca-cli not found!"
    find /opt/rebecca -maxdepth 3 -type f -print
    exit 1
fi

chmod +x "$CLI"

echo "[INFO] CLI: $CLI"

# ======================================
# Locate Server
# ======================================

if [ -x "/opt/rebecca/rebecca-server" ]; then
    SERVER="/opt/rebecca/rebecca-server"
elif [ -x "/opt/rebecca/dist/rebecca-server" ]; then
    SERVER="/opt/rebecca/dist/rebecca-server"
else
    SERVER="$(find /opt/rebecca -type f -name 'rebecca-server' -print -quit)"
fi

if [ -z "${SERVER:-}" ]; then
    echo "[ERROR] rebecca-server not found!"
    find /opt/rebecca -maxdepth 3 -type f -print
    exit 1
fi

chmod +x "$SERVER"

echo "[INFO] Server: $SERVER"

# ======================================
# Database Migration
# ======================================

echo "[INFO] Running database migrations..."

"$CLI" migrate up

echo "[INFO] Database migration completed."

# ======================================
# SQLite
# ======================================

echo "[INFO] Configuring SQLite..."

if [ -f "$DB_PATH" ]; then
    sqlite3 "$DB_PATH" <<'SQL'
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA busy_timeout=60000;
PRAGMA wal_autocheckpoint=1000;
SQL
fi

echo "[INFO] SQLite configured."

# ======================================
# Create Admin
# ======================================

echo "[INFO] Creating admin account..."

if "$CLI" admin create \
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

echo "[INFO] Starting Rebecca..."

exec "$SERVER"
