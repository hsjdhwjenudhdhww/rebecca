FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV HOST=0.0.0.0
ENV PORT=8080
ENV DATABASE=sqlite:////var/lib/rebecca/rebecca.db
ENV SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/rebecca/rebecca.db
ENV XRAY_LOCATION_ASSET=/usr/local/share/xray

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    wget \
    unzip \
    tar \
    gzip \
    sqlite3 \
    bash \
    procps \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Directories
RUN mkdir -p \
    /opt/rebecca \
    /var/lib/rebecca \
    /usr/local/share/xray

WORKDIR /opt/rebecca

# ============================================================
# Xray Core 26.3.27
# ============================================================

RUN set -eux; \
    mkdir -p /tmp/xray; \
    curl -fL --retry 5 --retry-all-errors \
    "https://github.com/XTLS/Xray-core/releases/download/v26.3.27/Xray-linux-64.zip" \
    -o /tmp/xray/xray.zip; \
    unzip -q /tmp/xray/xray.zip -d /tmp/xray; \
    test -f /tmp/xray/xray; \
    install -m 0755 /tmp/xray/xray /usr/local/bin/xray; \
    if [ -f /tmp/xray/geoip.dat ]; then \
        install -m 0644 /tmp/xray/geoip.dat /usr/local/share/xray/geoip.dat; \
    fi; \
    if [ -f /tmp/xray/geosite.dat ]; then \
        install -m 0644 /tmp/xray/geosite.dat /usr/local/share/xray/geosite.dat; \
    fi; \
    /usr/local/bin/xray version; \
    rm -rf /tmp/xray

# ============================================================
# Rebecca Panel
# ============================================================

RUN set -eux; \
    mkdir -p /tmp/rebecca; \
    curl -fL --retry 5 --retry-all-errors \
    "https://github.com/rebeccapanel/Rebecca/releases/latest/download/rebecca-linux-amd64.tar.gz" \
    -o /tmp/rebecca/rebecca.tar.gz; \
    tar -xzf /tmp/rebecca/rebecca.tar.gz -C /tmp/rebecca; \
    echo "=== Rebecca release files ==="; \
    find /tmp/rebecca -maxdepth 5 -type f -print; \
    CLI="$(find /tmp/rebecca -type f -name 'rebecca-cli' -print -quit)"; \
    SERVER="$(find /tmp/rebecca -type f -name 'rebecca-server' -print -quit)"; \
    echo "CLI=$CLI"; \
    echo "SERVER=$SERVER"; \
    test -n "$CLI"; \
    test -n "$SERVER"; \
    install -m 0755 "$CLI" /opt/rebecca/rebecca-cli; \
    install -m 0755 "$SERVER" /opt/rebecca/rebecca-server; \
    /opt/rebecca/rebecca-cli --help; \
    rm -rf /tmp/rebecca

# ============================================================
# Start script
# ============================================================

RUN cat > /start.sh <<'EOF'
#!/bin/bash
set -e

echo "======================================"
echo "        Rebecca Panel v0.1.4"
echo "             Railway"
echo "======================================"

export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-8080}"
export DATABASE="${DATABASE:-sqlite:////var/lib/rebecca/rebecca.db}"
export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-$DATABASE}"
export XRAY_LOCATION_ASSET="${XRAY_LOCATION_ASSET:-/usr/local/share/xray}"

mkdir -p /var/lib/rebecca

echo "[INFO] HOST=$HOST"
echo "[INFO] PORT=$PORT"
echo "[INFO] DATABASE=$DATABASE"
echo "[INFO] SQLALCHEMY_DATABASE_URL=$SQLALCHEMY_DATABASE_URL"

# Xray check
if [ -x /usr/local/bin/xray ]; then
    echo "[INFO] Xray Core found"
    /usr/local/bin/xray version
else
    echo "[ERROR] Xray Core not found"
    exit 1
fi

# Rebecca binaries
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

# ============================================================
# Database migrations
# ============================================================

echo "[INFO] Running database migrations..."

cd /opt/rebecca

/opt/rebecca/rebecca-cli migrate up || {
    echo "[ERROR] Database migration failed"
    exit 1
}

echo "[INFO] Database migration completed."

# ============================================================
# Default admin
# username: admin
# password: admin
# role: full_access
# ============================================================

echo "[INFO] Checking admin account..."

if /opt/rebecca/rebecca-cli admin show admin >/dev/null 2>&1; then
    echo "[INFO] Admin 'admin' already exists."
else
    echo "[INFO] Creating default admin..."

    /opt/rebecca/rebecca-cli admin create admin \
        --password admin \
        --role full_access

    echo "[INFO] Admin 'admin' created successfully."
fi

# ============================================================
# Start Rebecca
# ============================================================

echo "======================================"
echo "        Starting Rebecca"
echo "======================================"

echo "[INFO] Listening on $HOST:$PORT"
echo "[INFO] Railway PORT=$PORT"

exec /opt/rebecca/rebecca-server
EOF

RUN chmod +x /start.sh

# Railway
EXPOSE 8080

ENTRYPOINT ["/start.sh"]