#!/bin/sh

set -eu

echo "======================================"
echo "        Rebecca Panel v0.1.4          "
echo "             Railway                  "
echo "======================================"

PORT="${PORT:-8080}"

export UVICORN_HOST="0.0.0.0"
export UVICORN_PORT="$PORT"
export REBECCA_GATEWAY_ADDR="0.0.0.0:${PORT}"
export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

mkdir -p /var/lib/rebecca

CLI="/opt/rebecca/rebecca-cli"
SERVER="/opt/rebecca/rebecca-server"
DB_PATH="/var/lib/rebecca/rebecca.db"

echo "[INFO] GLIBC:"
ldd --version | head -n 1

echo "[INFO] HOST=0.0.0.0"
echo "[INFO] PORT=${PORT}"
echo "[INFO] GATEWAY=0.0.0.0:${PORT}"
echo "[INFO] DATABASE=${SQLALCHEMY_DATABASE_URL}"

# ======================================
# Start Rebecca
# ======================================

"$SERVER" &
SERVER_PID=$!

# ======================================
# Wait for HTTP server
# ======================================

echo "[INFO] Waiting for Rebecca..."

READY=0

for i in $(seq 1 300); do

    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "[ERROR] Rebecca stopped during startup."
        wait "$SERVER_PID" || true
        exit 1
    fi

    if curl -fsS \
        --connect-timeout 2 \
        --max-time 3 \
        "http://0.0.0.0:${PORT}/" \
        >/dev/null 2>&1
    then
        READY=1
        break
    fi

    sleep 1
done

if [ "$READY" -ne 1 ]; then
    echo "[ERROR] Rebecca did not become ready after 300 seconds."
    exit 1
fi

echo "[INFO] Rebecca is ready."

# ======================================
# SQLite
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
# Username: admin
# Password: admin1
# Telegram ID: empty
# Role: full_access
# ======================================

echo "[INFO] Creating admin account..."

"$CLI" admin create \
    --username admin \
    --password admin1 \
    --role full_access \
    || echo "[INFO] Admin already exists or creation was rejected."

echo "[INFO] Admin setup finished."

# ======================================
# Keep server alive
# ======================================

wait "$SERVER_PID"
