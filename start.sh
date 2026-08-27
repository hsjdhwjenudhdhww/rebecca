#!/bin/bash

set -u

echo "======================================"
echo "        Rebecca Panel v0.1.4"
echo "             Railway"
echo "======================================"

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-1234}"

export UVICORN_HOST="$HOST"
export UVICORN_PORT="$PORT"

export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

mkdir -p /var/lib/rebecca
mkdir -p /opt/rebecca

echo "[INFO] HOST=$HOST"
echo "[INFO] PORT=$PORT"
echo "[INFO] DATABASE=$SQLALCHEMY_DATABASE_URL"

# ---------------------------------------------------------
# Check Xray
# ---------------------------------------------------------

if command -v xray >/dev/null 2>&1; then
    echo "[INFO] Xray Core found"
    xray version || true
else
    echo "[ERROR] Xray Core not found"
    exit 1
fi

# ---------------------------------------------------------
# Check Rebecca
# ---------------------------------------------------------

if [ -x /opt/rebecca/rebecca-cli ]; then
    echo "[INFO] rebecca-cli found"
else
    echo "[ERROR] rebecca-cli not found"
    exit 1
fi

if [ -x /opt/rebecca/rebecca-server ]; then
    echo "[INFO] rebecca-server found"
else
    echo "[ERROR] rebecca-server not found"
    exit 1
fi

# ---------------------------------------------------------
# Database migration
# ---------------------------------------------------------

echo "[INFO] Running database migrations..."

if /opt/rebecca/rebecca-cli migrate up; then
    echo "[INFO] Database migration completed"
else
    echo "[ERROR] Database migration failed"
    exit 1
fi

# ---------------------------------------------------------
# Admin
# ---------------------------------------------------------

ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"

echo "[INFO] Checking admin account..."

# IMPORTANT:
# Do NOT call interactive:
# rebecca-cli admin create
#
# Railway has no interactive stdin.
# The command above causes:
#
# Username: Aborted.
#
# Therefore only create the admin when credentials
# are explicitly supplied and use non-interactive
# arguments supported by the installed CLI.

if [ -n "$ADMIN_PASSWORD" ]; then

    echo "[INFO] Admin credentials supplied"
    echo "[INFO] Admin username: $ADMIN_USERNAME"

    # Try the CLI's non-interactive form.
    # If this version does not support these options,
    # don't crash the whole server.
    if /opt/rebecca/rebecca-cli admin create \
        --username "$ADMIN_USERNAME" \
        --password "$ADMIN_PASSWORD" \
        --role full_access; then

        echo "[INFO] Admin created successfully"

    else
        echo "[WARN] Admin creation command was not accepted."
        echo "[WARN] The database/server will still be started."
        echo "[WARN] Run 'rebecca-cli admin --help' to inspect this version."
    fi

else
    echo "[WARN] ADMIN_PASSWORD is not set."
    echo "[WARN] Skipping automatic admin creation."
fi

# ---------------------------------------------------------
# Start Rebecca
# ---------------------------------------------------------

echo "======================================"
echo "[INFO] Starting Rebecca server"
echo "[INFO] Listening on $HOST:$PORT"
echo "======================================"

exec /opt/rebecca/rebecca-server
