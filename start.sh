#!/bin/sh

set -eu

echo "======================================"
echo "        Rebecca Panel v0.1.4          "
echo "             Railway                  "
echo "======================================"

PORT="${PORT:-8080}"

export HOST="0.0.0.0"
export PORT="$PORT"

export UVICORN_HOST="0.0.0.0"
export UVICORN_PORT="$PORT"

export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

mkdir -p /var/lib/rebecca

CLI="/opt/rebecca/rebecca-cli"
SERVER="/opt/rebecca/rebecca-server"
DB_PATH="/var/lib/rebecca/rebecca.db"

echo "[INFO] GLIBC:"
ldd --version | head -n 1

echo "[INFO] HOST=0.0.0.0"
echo "[INFO] PORT=${PORT}"
echo "[INFO] DATABASE=${SQLALCHEMY_DATABASE_URL}"

# ======================================
# Start Rebecca
# ======================================

echo "[INFO] Starting Rebecca..."

"$SERVER" &
SERVER_PID=$!

# ======================================
# Wait for Rebecca
# ======================================

echo "[INFO] Waiting for Rebecca startup..."

READY=0

for i in $(seq 1 180); do

    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "[ERROR] Rebecca server stopped."
        wait "$SERVER_PID" || true
        exit 1
    fi

    if curl -fsS "http://0.0.0.0:${PORT}/" >/dev/null 2>&1; then
        READY=1
        break
    fi

    sleep 1
done

if [ "$READY" -ne 1 ]; then
    echo "[ERROR] Rebecca did not become ready."
    exit 1
fi

echo "[INFO] Rebecca is ready on 0.0.0.0:${PORT}"

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
# Create Admin
# Telegram ID = empty
# Username = admin
# Password = admin1
# ======================================

echo "[INFO] Creating admin account..."

if command -v script >/dev/null 2>&1; then

    (
        sleep 1
        printf '\n'
    ) | script -qec \
        "$CLI admin create --username admin --password admin1 --role full_access" \
        /dev/null || true

else

    echo "[WARN] script command not found."
    "$CLI" admin create \
        --username admin \
        --password admin1 \
        --role full_access || true

fi

echo "[INFO] Admin setup finished."

# ======================================
# Keep Rebecca running
# ======================================

echo "[INFO] Rebecca is running on 0.0.0.0:${PORT}"

wait "$SERVER_PID"
