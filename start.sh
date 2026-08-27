#!/usr/bin/env bash

set -Eeuo pipefail

APP_DIR="/opt/rebecca"
DATA_DIR="/var/lib/rebecca"
DB_FILE="${DATA_DIR}/rebecca.db"

CLI="${APP_DIR}/rebecca-cli"
SERVER="${APP_DIR}/rebecca-server"
XRAY="/usr/local/bin/xray"

HOST="${UVICORN_HOST:-0.0.0.0}"
PORT="${PORT:-${UVICORN_PORT:-1234}}"

export UVICORN_HOST="$HOST"
export UVICORN_PORT="$PORT"

export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

export XRAY_EXECUTABLE_PATH="${XRAY_EXECUTABLE_PATH:-/usr/local/bin/xray}"
export XRAY_ASSETS_PATH="${XRAY_ASSETS_PATH:-/usr/local/share/xray}"

mkdir -p "$DATA_DIR"

echo "======================================"
echo "        Rebecca Panel"
echo "             Railway"
echo "======================================"

echo "[INFO] HOST=$UVICORN_HOST"
echo "[INFO] PORT=$UVICORN_PORT"
echo "[INFO] DATABASE=$DB_FILE"
echo "[INFO] SQLALCHEMY_DATABASE_URL=$SQLALCHEMY_DATABASE_URL"

# ------------------------------------------------------------
# Verify binaries
# ------------------------------------------------------------

if [ ! -x "$CLI" ]; then
    echo "[ERROR] rebecca-cli not found: $CLI"
    exit 1
fi

echo "[INFO] rebecca-cli found"

if [ ! -x "$SERVER" ]; then
    echo "[ERROR] rebecca-server not found: $SERVER"
    exit 1
fi

echo "[INFO] rebecca-server found"

if [ ! -x "$XRAY" ]; then
    echo "[ERROR] Xray not found: $XRAY"
    exit 1
fi

echo "[INFO] Xray Core found"

"$XRAY" version || true

# ------------------------------------------------------------
# Database migration
# ------------------------------------------------------------

echo "[INFO] Checking database..."

if [ ! -f "$DB_FILE" ]; then
    echo "[INFO] Database does not exist yet."
else
    echo "[INFO] Existing database found."
fi

echo "[INFO] Running database migrations..."

if ! "$CLI" migrate up; then
    echo "[ERROR] Database migration failed"
    exit 1
fi

echo "[INFO] Database migration completed successfully."

# ------------------------------------------------------------
# Admin
#
# IMPORTANT:
# Rebecca's CLI admin creation is interactive.
# Railway has no interactive TTY, therefore DO NOT run:
#
# rebecca-cli admin create ...
#
# here.
#
# The server must be allowed to start normally.
# ------------------------------------------------------------

echo "[INFO] Starting Rebecca server..."
echo "[INFO] Listening on ${UVICORN_HOST}:${UVICORN_PORT}"

exec "$SERVER"
