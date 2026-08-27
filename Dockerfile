FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV HOST=0.0.0.0
ENV PORT=8080
ENV DATABASE=sqlite:////var/lib/rebecca/rebecca.db
ENV SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/rebecca/rebecca.db

# =========================================================
# System packages
# =========================================================

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    unzip \
    sqlite3 \
    bash \
    procps \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# =========================================================
# Directories
# =========================================================

RUN mkdir -p \
    /opt/rebecca \
    /var/lib/rebecca \
    /usr/local/bin \
    /usr/local/share/xray

# =========================================================
# Install Rebecca using official installer
# =========================================================

RUN set -eux; \
    curl -fsSL \
    https://raw.githubusercontent.com/rebeccapanel/Rebecca/master/scripts/rebecca/rebecca-binary.sh \
    -o /tmp/rebecca-binary.sh; \
    chmod +x /tmp/rebecca-binary.sh; \
    /tmp/rebecca-binary.sh install || true; \
    rm -f /tmp/rebecca-binary.sh

# =========================================================
# Verify Rebecca binaries
# =========================================================

RUN set -eux; \
    echo "Checking Rebecca installation..."; \
    find /opt/rebecca -maxdepth 3 -type f -name 'rebecca-*' -print || true; \
    find /usr/local/bin -maxdepth 1 -type f -name 'rebecca-*' -print || true

# =========================================================
# Xray Core
# Version: 26.3.27
# =========================================================

RUN set -eux; \
    mkdir -p /tmp/xray-install; \
    curl -fL --retry 5 --retry-all-errors \
    "https://github.com/XTLS/Xray-core/releases/download/v26.3.27/Xray-linux-64.zip" \
    -o /tmp/xray-install/xray.zip; \
    unzip -o /tmp/xray-install/xray.zip \
    -d /tmp/xray-install; \
    test -f /tmp/xray-install/xray; \
    install -m 0755 \
    /tmp/xray-install/xray \
    /usr/local/bin/xray; \
    if [ -f /tmp/xray-install/geoip.dat ]; then \
        install -m 0644 \
        /tmp/xray-install/geoip.dat \
        /usr/local/share/xray/geoip.dat; \
    fi; \
    if [ -f /tmp/xray-install/geosite.dat ]; then \
        install -m 0644 \
        /tmp/xray-install/geosite.dat \
        /usr/local/share/xray/geosite.dat; \
    fi; \
    echo "Xray Core installed:"; \
    /usr/local/bin/xray version; \
    rm -rf /tmp/xray-install

# =========================================================
# Create start.sh
# =========================================================

RUN cat > /start.sh <<'EOF'
#!/bin/bash

set -u

echo "======================================"
echo "        Rebecca Panel v0.1.4"
echo "             Railway"
echo "======================================"

export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-8080}"

export DATABASE="${DATABASE:-sqlite:////var/lib/rebecca/rebecca.db}"
export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-$DATABASE}"

mkdir -p /var/lib/rebecca

echo "[INFO] HOST=$HOST"
echo "[INFO] PORT=$PORT"
echo "[INFO] DATABASE=$DATABASE"
echo "[INFO] SQLALCHEMY_DATABASE_URL=$SQLALCHEMY_DATABASE_URL"

# =========================================================
# Xray
# =========================================================

if [ -x /usr/local/bin/xray ]; then
    echo "[INFO] Xray Core found"
    /usr/local/bin/xray version || true
else
    echo "[ERROR] Xray Core not found"
fi

# =========================================================
# Locate Rebecca binaries
# =========================================================

REBECCA_CLI=""

if [ -x /opt/rebecca/rebecca-cli ]; then
    REBECCA_CLI="/opt/rebecca/rebecca-cli"
elif [ -x /usr/local/bin/rebecca-cli ]; then
    REBECCA_CLI="/usr/local/bin/rebecca-cli"
else
    FOUND_CLI="$(find /opt/rebecca /usr/local/bin \
        -type f \
        -name 'rebecca-cli' \
        -print -quit 2>/dev/null || true)"

    if [ -n "$FOUND_CLI" ]; then
        REBECCA_CLI="$FOUND_CLI"
    fi
fi

REBECCA_SERVER=""

if [ -x /opt/rebecca/rebecca-server ]; then
    REBECCA_SERVER="/opt/rebecca/rebecca-server"
elif [ -x /usr/local/bin/rebecca-server ]; then
    REBECCA_SERVER="/usr/local/bin/rebecca-server"
else
    FOUND_SERVER="$(find /opt/rebecca /usr/local/bin \
        -type f \
        -name 'rebecca-server' \
        -print -quit 2>/dev/null || true)"

    if [ -n "$FOUND_SERVER" ]; then
        REBECCA_SERVER="$FOUND_SERVER"
    fi
fi

echo "[INFO] CLI=$REBECCA_CLI"
echo "[INFO] SERVER=$REBECCA_SERVER"

if [ -z "$REBECCA_CLI" ]; then
    echo "[ERROR] rebecca-cli not found"
    exit 1
fi

if [ -z "$REBECCA_SERVER" ]; then
    echo "[ERROR] rebecca-server not found"
    exit 1
fi

chmod +x "$REBECCA_CLI" "$REBECCA_SERVER"

echo "[INFO] rebecca-cli found"
echo "[INFO] rebecca-server found"

# =========================================================
# Database migration
# =========================================================

echo "[INFO] Running database migrations..."

"$REBECCA_CLI" migrate up || {
    echo "[WARN] Migration command returned an error."
}

echo "[INFO] Database migration completed."

# =========================================================
# Default admin
#
# Username: admin
# Password: admin
# Role: full_access
# =========================================================

echo "[INFO] Checking admin account..."

if "$REBECCA_CLI" admin list 2>/dev/null | \
    grep -qE '(^|[[:space:]])admin([[:space:]]|$)'; then

    echo "[INFO] Admin 'admin' already exists."

else

    echo "[INFO] Creating default admin..."

    "$REBECCA_CLI" admin create admin \
        --password admin \
        --role full_access

    if [ $? -eq 0 ]; then
        echo "[INFO] Admin 'admin' created successfully."
    else
        echo "[WARN] Failed to create default admin."
    fi

fi

# =========================================================
# Start Rebecca
# =========================================================

echo "======================================"
echo "        Starting Rebecca"
echo "======================================"

echo "[INFO] Listening on ${HOST}:${PORT}"
echo "[INFO] Railway PORT=${PORT}"

exec "$REBECCA_SERVER" \
    --host "$HOST" \
    --port "$PORT"
EOF

RUN chmod +x /start.sh

# =========================================================
# Railway
# =========================================================

EXPOSE 8080

ENTRYPOINT ["/bin/bash", "/start.sh"]