#!/bin/sh

set -eu

echo "======================================"
echo "        Rebecca Panel v0.1.4          "
echo "             Railway                  "
echo "======================================"

PORT="${PORT:-8080}"

export UVICORN_HOST="0.0.0.0"
export UVICORN_PORT="$PORT"
export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

mkdir -p /var/lib/rebecca

CLI="/opt/rebecca/rebecca-cli"
SERVER="/opt/rebecca/rebecca-server"
DB_PATH="/var/lib/rebecca/rebecca.db"

echo "[INFO] GLIBC:"
ldd --version | head -n 1

echo "[INFO] PORT=${PORT}"
echo "[INFO] DATABASE=${SQLALCHEMY_DATABASE_URL}"

echo "[INFO] Starting Rebecca..."

"$SERVER" &
SERVER_PID=$!

echo "[INFO] Waiting for Rebecca..."

i=0

while ! curl -fsS "http://127.0.0.1:${PORT}/" >/dev/null 2>&1; do
    i=$((i + 1))

    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "[ERROR] Rebecca stopped during startup."
        wait "$SERVER_PID" || true
        exit 1
    fi

    if [ "$i" -ge 60 ]; then
        echo "[ERROR] Rebecca did not become ready."
        exit 1
    fi

    sleep 1
done

echo "[INFO] Rebecca is ready."

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

echo "[INFO] Creating admin account..."

if command -v script >/dev/null 2>&1; then
    (
        sleep 1
        printf '\n'
    ) | script -qec \
        "$CLI admin create --username admin --password admin --role full_access" \
        /dev/null || true
else
    echo "[WARN] script command not found."
fi

echo "[INFO] Rebecca is running."

wait "$SERVER_PID"
