#!/bin/sh

set -eu

echo ""
echo "======================================"
echo "        Rebecca Panel                 "
echo "             Railway                  "
echo "======================================"
echo ""

# ============================================================
# Railway PORT
# ============================================================

PORT="${PORT:-8080}"

export PORT="$PORT"

# Rebecca gateway MUST listen on all interfaces.
export HOST="0.0.0.0"
export UVICORN_HOST="0.0.0.0"
export UVICORN_PORT="$PORT"

# This has priority over UVICORN_HOST/UVICORN_PORT
export REBECCA_GATEWAY_ADDR="0.0.0.0:${PORT}"

# ============================================================
# Database
# ============================================================

export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

mkdir -p /var/lib/rebecca

echo "[INFO] PORT=${PORT}"
echo "[INFO] HOST=0.0.0.0"
echo "[INFO] GATEWAY=${REBECCA_GATEWAY_ADDR}"
echo "[INFO] DATABASE=${SQLALCHEMY_DATABASE_URL}"

echo ""

# ============================================================
# Check binaries
# ============================================================

if [ ! -x /opt/rebecca/rebecca-cli ]; then
    echo "[ERROR] rebecca-cli not found"
    exit 1
fi

if [ ! -x /opt/rebecca/rebecca-server ]; then
    echo "[ERROR] rebecca-server not found"
    exit 1
fi

echo "[INFO] rebecca-cli found"
echo "[INFO] rebecca-server found"

# ============================================================
# Database migration
# ============================================================

echo ""
echo "[INFO] Running Rebecca database migrations..."
echo ""

cd /opt/rebecca

/opt/rebecca/rebecca-cli migrate up

echo ""
echo "[INFO] Database migration completed."

# ============================================================
# Create admin
# ============================================================

echo ""
echo "[INFO] Creating admin account..."
echo ""

# IMPORTANT:
# Rebecca's official CLI syntax supports:
# rebecca cli admin create --role full_access
#
# The CLI may prompt for username/password.
#
# We try the non-interactive environment-supported route first.

if [ -n "${REBECCA_ADMIN_USERNAME:-}" ] && [ -n "${REBECCA_ADMIN_PASSWORD:-}" ]; then

    echo "[INFO] Admin credentials supplied through environment."

    printf '%s\n%s\n' \
        "$REBECCA_ADMIN_USERNAME" \
        "$REBECCA_ADMIN_PASSWORD" \
        | /opt/rebecca/rebecca-cli cli admin create --role full_access \
        || echo "[WARN] Admin creation returned non-zero."

else

    echo "[INFO] No admin environment variables supplied."
    echo "[INFO] Skipping automatic admin creation."

fi

# ============================================================
# Start Rebecca
# ============================================================

echo ""
echo "======================================"
echo "        Starting Rebecca             "
echo "======================================"
echo ""
echo "[INFO] Listening on ${REBECCA_GATEWAY_ADDR}"
echo "[INFO] Railway PORT=${PORT}"
echo ""

exec /opt/rebecca/rebecca-server
