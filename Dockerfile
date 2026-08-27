FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Railway
ENV HOST=0.0.0.0
ENV PORT=8080

# Rebecca
ENV DATABASE=sqlite:////var/lib/rebecca/rebecca.db
ENV SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/rebecca/rebecca.db

# =========================================================
# Packages
# =========================================================

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    unzip \
    sqlite3 \
    bash \
    procps \
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

WORKDIR /opt/rebecca

# =========================================================
# Xray Core 26.3.27
# =========================================================

RUN set -eux; \
    mkdir -p /tmp/xray; \
    curl -fL --retry 5 --retry-all-errors \
    "https://github.com/XTLS/Xray-core/releases/download/v26.3.27/Xray-linux-64.zip" \
    -o /tmp/xray/xray.zip; \
    unzip -o /tmp/xray/xray.zip -d /tmp/xray; \
    test -f /tmp/xray/xray; \
    install -m 0755 \
    /tmp/xray/xray \
    /usr/local/bin/xray; \
    if [ -f /tmp/xray/geoip.dat ]; then \
        install -m 0644 \
        /tmp/xray/geoip.dat \
        /usr/local/share/xray/geoip.dat; \
    fi; \
    if [ -f /tmp/xray/geosite.dat ]; then \
        install -m 0644 \
        /tmp/xray/geosite.dat \
        /usr/local/share/xray/geosite.dat; \
    fi; \
    /usr/local/bin/xray version; \
    rm -rf /tmp/xray

# =========================================================
# Rebecca
#
# Official GitHub release
# =========================================================

RUN set -eux; \
    mkdir -p /tmp/rebecca; \
    curl -fL --retry 5 --retry-all-errors \
    "https://github.com/rebeccapanel/Rebecca/releases/latest/download/rebecca-linux-amd64.tar.gz" \
    -o /tmp/rebecca/rebecca.tar.gz; \
    tar -xzf /tmp/rebecca/rebecca.tar.gz \
    -C /tmp/rebecca; \
    echo "=== Rebecca release files ==="; \
    find /tmp/rebecca -type f -maxdepth 4 -print; \
    CLI="$(find /tmp/rebecca -type f -name 'rebecca-cli' -print -quit)"; \
    SERVER="$(find /tmp/rebecca -type f -name 'rebecca-server' -print -quit)"; \
    test -n "$CLI"; \
    test -n "$SERVER"; \
    install -m 0755 "$CLI" /opt/rebecca/rebecca-cli; \
    install -m 0755 "$SERVER" /opt/rebecca/rebecca-server; \
    rm -rf /tmp/rebecca; \
    /opt/rebecca/rebecca-cli --help; \
    /opt/rebecca/rebecca-server --help || true

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
    /usr/local/bin/xray version
else
    echo "[ERROR] Xray Core not found"
    exit 1
fi

# =========================================================
# Rebecca
# =========================================================

REBECCA_CLI="/opt/rebecca/rebecca-cli"
REBECCA_SERVER="/opt/rebecca/rebecca-server"

if [ ! -x "$REBECCA_CLI" ]; then
    echo "[ERROR] rebecca-cli not found"
    exit 1
fi

if [ ! -x "$REBECCA_SERVER" ]; then
    echo "[ERROR] rebecca-server not found"
    exit 1
fi

echo "[INFO] rebecca-cli found"
echo "[INFO] rebecca-server found"

# =========================================================
# Database migration
# =========================================================

echo "[INFO] Running database migrations..."

"$REBECCA_CLI" migrate up

if [ $? -ne 0 ]; then
    echo "[ERROR] Database migration failed"
    exit 1
fi

echo "[INFO] Database migration completed."

# =========================================================
# Admin
#
# Username: admin
# Password: admin
# Role: full_access
# =========================================================

echo "[INFO] Checking admin account..."

if "$REBECCA_CLI" admin list 2>/dev/null | \
   grep -qE '(^|[[:space:]])admin([[:space:]]|$)'
then

    echo "[INFO] Admin 'admin' already exists."

else

    echo "[INFO] Creating default admin..."

    "$REBECCA_CLI" admin create admin \
        --password admin \
        --role full_access

    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to create admin"
        exit 1
    fi

    echo "[INFO] Admin 'admin' created successfully."

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
# Railway port
# =========================================================

EXPOSE 8080

ENTRYPOINT ["/bin/bash", "/start.sh"]