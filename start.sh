#!/usr/bin/env bash

set -Eeuo pipefail

# ==========================================================
# Configuration
# ==========================================================

PANEL_PORT="8080"
NODE_PORT="5000"

APP_DIR="/opt/rebecca"
DATA_DIR="/var/lib/rebecca"

REBECCA_SERVER="${APP_DIR}/bin/rebecca-server"
REBECCA_CLI="${APP_DIR}/bin/rebecca-cli"
XRAY_BIN="/usr/local/bin/xray"

export DEBIAN_FRONTEND=noninteractive

# ==========================================================
# Banner
# ==========================================================

echo
echo "=========================================="
echo "          Rebecca Railway"
echo "=========================================="
echo "Panel : ${PANEL_PORT}"
echo "Node  : ${NODE_PORT}"
echo "=========================================="
echo

# ==========================================================
# Directories
# ==========================================================

mkdir -p \
    "${DATA_DIR}" \
    "${DATA_DIR}/certs"

# ==========================================================
# Verify Rebecca
# ==========================================================

if [ ! -f "${REBECCA_SERVER}" ]; then

    echo "[ERROR] Rebecca server binary does not exist:"
    echo "${REBECCA_SERVER}"

    echo
    echo "Rebecca files:"
    find "${APP_DIR}" \
        -maxdepth 5 \
        -type f \
        -print 2>/dev/null || true

    exit 1

fi

chmod +x "${REBECCA_SERVER}"

echo "[OK] Rebecca binary found:"
echo "     ${REBECCA_SERVER}"

# ==========================================================
# Verify Xray
# ==========================================================

if [ ! -x "${XRAY_BIN}" ]; then

    echo "[ERROR] Xray binary not found:"
    echo "${XRAY_BIN}"

    exit 1

fi

echo
echo "[OK] Xray found:"
echo "     ${XRAY_BIN}"

echo
echo "[+] Xray version:"
"${XRAY_BIN}" version || true

# ==========================================================
# Rebecca environment
# ==========================================================

export HOST="0.0.0.0"
export PORT="${PANEL_PORT}"

export UVICORN_HOST="0.0.0.0"
export UVICORN_PORT="${PANEL_PORT}"

export REBECCA_GATEWAY_ADDR="0.0.0.0:${PANEL_PORT}"

export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

export REBECCA_CERT_BASE="${REBECCA_CERT_BASE:-/var/lib/rebecca/certs}"

export REBECCA_CONFIG_DIR="${REBECCA_CONFIG_DIR:-/var/lib/rebecca}"

# ==========================================================
# Create Rebecca .env
# ==========================================================

cat > "${APP_DIR}/.env" <<EOF
HOST=0.0.0.0
PORT=${PANEL_PORT}

UVICORN_HOST=0.0.0.0
UVICORN_PORT=${PANEL_PORT}

REBECCA_GATEWAY_ADDR=0.0.0.0:${PANEL_PORT}

SQLALCHEMY_DATABASE_URL=${SQLALCHEMY_DATABASE_URL}

REBECCA_CERT_BASE=${REBECCA_CERT_BASE}

REBECCA_CONFIG_DIR=${REBECCA_CONFIG_DIR}
EOF

echo
echo "[OK] Rebecca environment configured."

# ==========================================================
# Database migration
# ==========================================================

echo
echo "[+] Running database migrations..."

if [ -x "${REBECCA_CLI}" ]; then

    "${REBECCA_CLI}" migrate up || {
        echo "[WARN] Migration returned non-zero."
        echo "[WARN] Continuing anyway."
    }

else

    echo "[WARN] Rebecca CLI not found:"
    echo "       ${REBECCA_CLI}"

fi

# ==========================================================
# Admin information
# ==========================================================

ADMIN_USERNAME="${REBECCA_ADMIN_USERNAME:-admin1}"
ADMIN_PASSWORD="${REBECCA_ADMIN_PASSWORD:-admin123}"

echo
echo "=========================================="
echo "          Rebecca Admin"
echo "=========================================="
echo
echo "Username : ${ADMIN_USERNAME}"
echo "Password : ${ADMIN_PASSWORD}"
echo "Telegram : <empty>"
echo
echo "=========================================="

# ==========================================================
# Railway domain
# ==========================================================

DOMAIN="${RAILWAY_PUBLIC_DOMAIN:-}"

if [ -z "${DOMAIN}" ]; then
    DOMAIN="${RAILWAY_STATIC_URL:-}"
fi

if [ -n "${DOMAIN}" ]; then

    case "${DOMAIN}" in
        http://*|https://*)
            PUBLIC_URL="${DOMAIN}"
            ;;
        *)
            PUBLIC_URL="https://${DOMAIN}"
            ;;
    esac

    echo
    echo "=========================================="
    echo "        Rebecca Public Information"
    echo "=========================================="
    echo
    echo "Domain:"
    echo "${PUBLIC_URL}"
    echo
    echo "Dashboard:"
    echo "${PUBLIC_URL}/dashboard/"
    echo
    echo "Node Master URL:"
    echo "${PUBLIC_URL}"
    echo
    echo "=========================================="

else

    echo
    echo "[WARN] Railway public domain not available."
    echo "[WARN] Generate a public domain for this service."

fi

# ==========================================================
# Runtime
# ==========================================================

echo
echo "=========================================="
echo "              Runtime"
echo "=========================================="
echo
echo "Rebecca:"
echo "  0.0.0.0:${PANEL_PORT}"
echo
echo "Xray:"
echo "  ${XRAY_BIN}"
echo
echo "Reserved Node port:"
echo "  ${NODE_PORT}"
echo
echo "=========================================="

# ==========================================================
# Start Rebecca
# ==========================================================

echo
echo "[+] Starting Rebecca..."
echo "[+] Listening on 0.0.0.0:${PANEL_PORT}"
echo

cd "${APP_DIR}"

exec "${REBECCA_SERVER}"