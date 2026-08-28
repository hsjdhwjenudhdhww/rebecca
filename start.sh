#!/usr/bin/env bash

set -Eeuo pipefail

PANEL_PORT="8080"
NODE_PORT="5000"

APP_DIR="/opt/rebecca"
DATA_DIR="/var/lib/rebecca"

export DEBIAN_FRONTEND=noninteractive

echo
echo "=========================================="
echo "          Rebecca Railway"
echo "=========================================="
echo "Panel : ${PANEL_PORT}"
echo "Node  : ${NODE_PORT}"
echo "=========================================="
echo

mkdir -p \
    "${APP_DIR}" \
    "${DATA_DIR}" \
    "${DATA_DIR}/certs"

# ==========================================================
# INSTALL REBECCA
# ==========================================================

if [ ! -x "${APP_DIR}/bin/rebecca-server" ]; then

    echo "[+] Installing Rebecca..."

    curl -fsSL \
        https://raw.githubusercontent.com/rebeccapanel/Rebecca/master/scripts/rebecca/rebecca-binary.sh \
        -o /tmp/rebecca-install.sh

    chmod +x /tmp/rebecca-install.sh

    /tmp/rebecca-install.sh install --database sqlite

fi

# ==========================================================
# VERIFY REBECCA
# ==========================================================

if [ ! -x "${APP_DIR}/bin/rebecca-server" ]; then

    echo
    echo "[ERROR] Rebecca installation failed."
    echo

    find /opt/rebecca \
        -maxdepth 5 \
        -type f \
        -print 2>/dev/null || true

    exit 1

fi

echo "[OK] Rebecca installed."

# ==========================================================
# INSTALL XRAY - STANDALONE
# NO SYSTEMD
# ==========================================================

XRAY_BIN="/usr/local/bin/xray"

if [ ! -x "${XRAY_BIN}" ]; then

    echo
    echo "[+] Installing standalone Xray-core..."

    ARCH="$(uname -m)"

    case "${ARCH}" in

        x86_64|amd64)
            XRAY_ASSET="Xray-linux-64.zip"
            ;;

        aarch64|arm64)
            XRAY_ASSET="Xray-linux-arm64-v8a.zip"
            ;;

        armv7l|armv7)
            XRAY_ASSET="Xray-linux-arm32-v7a.zip"
            ;;

        *)
            echo "[ERROR] Unsupported architecture: ${ARCH}"
            exit 1
            ;;

    esac

    XRAY_TMP="$(mktemp -d)"

    echo "[+] Architecture : ${ARCH}"
    echo "[+] Package      : ${XRAY_ASSET}"

    curl -fL \
        --retry 5 \
        --retry-delay 2 \
        --connect-timeout 20 \
        "https://github.com/XTLS/Xray-core/releases/latest/download/${XRAY_ASSET}" \
        -o "${XRAY_TMP}/xray.zip"

    echo "[+] Extracting Xray..."

    unzip -oq \
        "${XRAY_TMP}/xray.zip" \
        -d "${XRAY_TMP}/xray"

    if [ ! -f "${XRAY_TMP}/xray/xray" ]; then

        echo "[ERROR] Xray binary not found."

        find "${XRAY_TMP}/xray" \
            -maxdepth 3 \
            -type f \
            -print 2>/dev/null || true

        rm -rf "${XRAY_TMP}"

        exit 1

    fi

    install -m 0755 \
        "${XRAY_TMP}/xray/xray" \
        "${XRAY_BIN}"

    rm -rf "${XRAY_TMP}"

fi

# ==========================================================
# VERIFY XRAY
# ==========================================================

if [ ! -x "${XRAY_BIN}" ]; then

    echo "[ERROR] Xray installation failed."

    exit 1

fi

echo
echo "=========================================="
echo "              Xray Core"
echo "=========================================="

"${XRAY_BIN}" version || true

echo "=========================================="
echo

# ==========================================================
# REBECCA ENVIRONMENT
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
# CREATE ENV FILE
# ==========================================================

cat > "${APP_DIR}/.env" <<EOF
UVICORN_HOST=0.0.0.0
UVICORN_PORT=${PANEL_PORT}

REBECCA_GATEWAY_ADDR=0.0.0.0:${PANEL_PORT}

SQLALCHEMY_DATABASE_URL=${SQLALCHEMY_DATABASE_URL}

REBECCA_CERT_BASE=${REBECCA_CERT_BASE}

REBECCA_CONFIG_DIR=${REBECCA_CONFIG_DIR}
EOF

echo "[OK] Environment configured."

# ==========================================================
# DATABASE MIGRATION
# ==========================================================

echo
echo "[+] Running database migrations..."

if [ -x "${APP_DIR}/bin/rebecca-cli" ]; then

    "${APP_DIR}/bin/rebecca-cli" migrate || {

        echo "[WARN] Migration returned non-zero."
        echo "[WARN] Continuing..."

    }

elif command -v rebecca >/dev/null 2>&1; then

    rebecca migrate || {

        echo "[WARN] Migration returned non-zero."
        echo "[WARN] Continuing..."

    }

else

    echo "[WARN] Rebecca CLI not found."

fi

# ==========================================================
# ADMIN
# ==========================================================

ADMIN_USERNAME="${REBECCA_ADMIN_USERNAME:-admin1}"

ADMIN_PASSWORD="${REBECCA_ADMIN_PASSWORD:-admin123}"

echo
echo "=========================================="
echo "         Rebecca Admin"
echo "=========================================="
echo
echo "Username : ${ADMIN_USERNAME}"
echo "Password : ${ADMIN_PASSWORD}"
echo "Telegram : <empty>"
echo
echo "=========================================="
echo

# ==========================================================
# RAILWAY DOMAIN
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
    echo "  ${PUBLIC_URL}"
    echo
    echo "Dashboard:"
    echo "  ${PUBLIC_URL}/dashboard/"
    echo
    echo "Master:"
    echo "  ${PUBLIC_URL}"
    echo
    echo "=========================================="
    echo

else

    echo "[WARN] Railway public domain unavailable."

fi

# ==========================================================
# RUNTIME INFORMATION
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
echo "Node target:"
echo "  ${NODE_PORT}"
echo
echo "=========================================="
echo

# ==========================================================
# START REBECCA
# ==========================================================

echo "[+] Starting Rebecca..."
echo "[+] Listening on 0.0.0.0:${PANEL_PORT}"
echo

cd "${APP_DIR}"

exec "${APP_DIR}/bin/rebecca-server"