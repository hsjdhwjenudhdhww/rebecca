#!/usr/bin/env bash
set -Eeuo pipefail

PANEL_PORT=8080
NODE_PORT=5000

export DEBIAN_FRONTEND=noninteractive

echo "=========================================="
echo " Rebecca Railway"
echo "=========================================="
echo "Panel : ${PANEL_PORT}"
echo "Node  : ${NODE_PORT}"
echo "=========================================="

# ------------------------------------------------
# Install Rebecca
# ------------------------------------------------

if [ ! -x /opt/rebecca/bin/rebecca-server ]; then

    echo "[+] Installing Rebecca..."

    curl -fsSL \
      https://raw.githubusercontent.com/rebeccapanel/Rebecca/master/scripts/rebecca/rebecca-binary.sh \
      | bash -s -- install --database sqlite

fi

# ------------------------------------------------
# Verify installation
# ------------------------------------------------

if [ ! -x /opt/rebecca/bin/rebecca-server ]; then
    echo "[ERROR] Rebecca installation failed."
    exit 1
fi

echo "[+] Rebecca installed."

# ------------------------------------------------
# Install Xray
# ------------------------------------------------

if ! command -v xray >/dev/null 2>&1; then

    echo "[+] Installing Xray-core..."

    curl -fsSL \
      https://github.com/XTLS/Xray-install/raw/main/install-release.sh \
      | bash -s -- install

fi

echo
echo "[+] Xray version:"
xray version || true

# ------------------------------------------------
# Environment
# ------------------------------------------------

export HOST=0.0.0.0
export PORT=${PANEL_PORT}

export UVICORN_HOST=0.0.0.0
export UVICORN_PORT=${PANEL_PORT}

# ------------------------------------------------
# Migration
# ------------------------------------------------

echo "[+] Running migrations..."

if command -v rebecca >/dev/null 2>&1; then
    rebecca migrate || true
fi

# ------------------------------------------------
# Admin credentials
# ------------------------------------------------

ADMIN_USERNAME="${REBECCA_ADMIN_USERNAME:-admin1}"
ADMIN_PASSWORD="${REBECCA_ADMIN_PASSWORD:-admin123}"

echo
echo "=========================================="
echo " Rebecca credentials"
echo "=========================================="
echo "Username : ${ADMIN_USERNAME}"
echo "Password : ${ADMIN_PASSWORD}"
echo "Telegram : <empty>"
echo "=========================================="
echo

# ------------------------------------------------
# Start
# ------------------------------------------------

echo "[+] Starting Rebecca..."

cd /opt/rebecca

exec /opt/rebecca/bin/rebecca-server