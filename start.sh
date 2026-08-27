#!/bin/sh

set -eu

echo "======================================"
echo "        Rebecca Panel - Railway       "
echo "======================================"

PORT="${PORT:-8080}"

export UVICORN_HOST="0.0.0.0"
export UVICORN_PORT="$PORT"

export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

mkdir -p /var/lib/rebecca

echo "[INFO] Listening on 0.0.0.0:${PORT}"
echo "[INFO] Database: ${SQLALCHEMY_DATABASE_URL}"

# ======================================
# Database migration
# ======================================

echo "[INFO] Running database migrations..."

/opt/rebecca/dist/rebecca-cli migrate up

echo "[INFO] Database migration completed."

# ======================================
# Create admin
# Username: admin
# Password: admin
# Role: full_access
# ======================================

echo "[INFO] Creating admin account..."

if /opt/rebecca/dist/rebecca-cli admin create \
    --username admin \
    --password admin \
    --role full_access
then
    echo "[INFO] Admin account created successfully."
else
    echo "[INFO] Admin already exists or creation was rejected."
fi

# ======================================
# SQLite
# ======================================

DB_PATH="/var/lib/rebecca/rebecca.db"

if [ -f "$DB_PATH" ]; then
    echo "[INFO] Configuring SQLite..."

    sqlite3 "$DB_PATH" <<'SQL'
PRAGMA journal_mode=WAL;
PRAGMA busy_timeout=30000;
PRAGMA synchronous=NORMAL;
SQL

    echo "[INFO] SQLite configured."
fi

# ======================================
# Start Rebecca
# ======================================

echo "[INFO] Starting Rebecca server..."

exec /opt/rebecca/dist/rebecca-server