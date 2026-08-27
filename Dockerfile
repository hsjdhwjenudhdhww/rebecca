FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Railway
ENV HOST=0.0.0.0
ENV PORT=8080

# Rebecca database
ENV DATABASE=sqlite:////var/lib/rebecca/rebecca.db
ENV SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/rebecca/rebecca.db

# Default admin
ENV ADMIN_USERNAME=admin
ENV ADMIN_PASSWORD=admin
ENV ADMIN_ROLE=full_access

# Xray
ENV XRAY_LOCATION_ASSET=/usr/local/share/xray

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    unzip \
    sqlite3 \
    bash \
    procps \
    git \
    && rm -rf /var/lib/apt/lists/*

# IMPORTANT:
# Do NOT create /opt/rebecca before Rebecca installer.
# The installer itself creates /opt/rebecca.
RUN set -eux; \
    curl -fsSL \
    https://raw.githubusercontent.com/rebeccapanel/Rebecca/master/scripts/rebecca/rebecca-binary.sh \
    -o /tmp/rebecca-binary.sh; \
    chmod +x /tmp/rebecca-binary.sh; \
    rm -rf /opt/rebecca; \
    /tmp/rebecca-binary.sh install; \
    rm -f /tmp/rebecca-binary.sh

# Make sure Xray exists
RUN set -eux; \
    test -x /opt/rebecca/rebecca-cli; \
    test -x /opt/rebecca/rebecca-server; \
    if [ -x /usr/local/bin/xray ]; then \
        /usr/local/bin/xray version; \
    elif [ -x /opt/rebecca/xray ]; then \
        /opt/rebecca/xray version; \
    else \
        echo "ERROR: Xray Core was not installed"; \
        find /opt/rebecca -maxdepth 3 -type f -name 'xray' -print; \
        exit 1; \
    fi

RUN mkdir -p /var/lib/rebecca /usr/local/share/xray

# Create startup script
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
export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

echo "[INFO] HOST=$HOST"
echo "[INFO] PORT=$PORT"
echo "[INFO] DATABASE=$DATABASE"
echo "[INFO] SQLALCHEMY_DATABASE_URL=$SQLALCHEMY_DATABASE_URL"

mkdir -p /var/lib/rebecca

CLI="/opt/rebecca/rebecca-cli"
SERVER="/opt/rebecca/rebecca-server"

if [ ! -x "$CLI" ]; then
    echo "[ERROR] rebecca-cli not found"
    exit 1
fi

if [ ! -x "$SERVER" ]; then
    echo "[ERROR] rebecca-server not found"
    exit 1
fi

echo "[INFO] rebecca-cli found"
echo "[INFO] rebecca-server found"

# --------------------------------------------------
# Database migration
# --------------------------------------------------

echo "[INFO] Running database migrations..."

"$CLI" migrate up

echo "[INFO] Database migration completed."

# --------------------------------------------------
# Create default admin
# --------------------------------------------------

echo "[INFO] Checking admin account..."

if "$CLI" admin show admin >/dev/null 2>&1; then
    echo "[INFO] Admin 'admin' already exists."

    # Ensure password is admin
    "$CLI" admin set-password admin --password admin || true

    # Ensure full access
    "$CLI" admin update admin --role full_access || true

    # Ensure enabled
    "$CLI" admin enable admin || true
else
    echo "[INFO] Creating default admin..."

    "$CLI" admin create admin \
        --password admin \
        --role full_access

    echo "[INFO] Admin 'admin' created successfully."
fi

# --------------------------------------------------
# Xray check
# --------------------------------------------------

if [ -x /usr/local/bin/xray ]; then
    echo "[INFO] Xray Core:"
    /usr/local/bin/xray version || true
elif [ -x /opt/rebecca/xray ]; then
    echo "[INFO] Xray Core:"
    /opt/rebecca/xray version || true
else
    echo "[WARN] Xray executable not found in expected locations."
fi

# --------------------------------------------------
# Start Rebecca
# --------------------------------------------------

echo "======================================"
echo "        Starting Rebecca"
echo "======================================"

echo "[INFO] Listening on ${HOST}:${PORT}"
echo "[INFO] Railway PORT=${PORT}"

exec "$SERVER"
EOF

RUN chmod +x /start.sh

EXPOSE 8080

ENTRYPOINT ["/start.sh"]