FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    unzip \
    zip \
    sqlite3 \
    build-essential \
    gcc \
    g++ \
    pkg-config \
    nodejs \
    npm \
    golang \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/rebecca

# Clone Rebecca
RUN git clone --depth 1 \
    https://github.com/rebeccapanel/Rebecca.git \
    source

WORKDIR /opt/rebecca/source

# --------------------------------------------------
# Install Xray Core
# --------------------------------------------------

RUN set -eux; \
    mkdir -p /usr/local/bin /usr/local/share/xray /tmp/xray; \
    curl -fL --retry 5 --retry-all-errors \
    "https://github.com/XTLS/Xray-core/releases/download/v26.3.27/Xray-linux-64.zip" \
    -o /tmp/xray/xray.zip; \
    unzip -o /tmp/xray/xray.zip -d /tmp/xray; \
    test -f /tmp/xray/xray; \
    install -m 0755 /tmp/xray/xray /usr/local/bin/xray; \
    if [ -f /tmp/xray/geoip.dat ]; then \
        cp /tmp/xray/geoip.dat /usr/local/share/xray/geoip.dat; \
    fi; \
    if [ -f /tmp/xray/geosite.dat ]; then \
        cp /tmp/xray/geosite.dat /usr/local/share/xray/geosite.dat; \
    fi; \
    /usr/local/bin/xray version; \
    rm -rf /tmp/xray

# --------------------------------------------------
# Build Dashboard
# --------------------------------------------------

RUN set -eux; \
    if [ -d dashboard ]; then \
        cd dashboard; \
        npm ci; \
        VITE_BASE_API=/api/ npm run build \
            -- --outDir=build \
            --assetsDir=statics; \
        cp build/index.html build/404.html; \
    fi

# --------------------------------------------------
# Build Rebecca binaries
# --------------------------------------------------

RUN set -eux; \
    chmod +x scripts/build_binary.sh; \
    bash scripts/build_binary.sh

# --------------------------------------------------
# Install generated binaries
# --------------------------------------------------

RUN set -eux; \
    mkdir -p /opt/rebecca /var/lib/rebecca; \
    test -f dist/rebecca-cli; \
    test -f dist/rebecca-server; \
    cp dist/rebecca-cli /opt/rebecca/rebecca-cli; \
    cp dist/rebecca-server /opt/rebecca/rebecca-server; \
    chmod +x /opt/rebecca/rebecca-cli; \
    chmod +x /opt/rebecca/rebecca-server; \
    /opt/rebecca/rebecca-cli --help; \
    /opt/rebecca/rebecca-server --help || true

# --------------------------------------------------
# Xray permissions
# --------------------------------------------------

RUN chmod +x /usr/local/bin/xray

# --------------------------------------------------
# Environment
# --------------------------------------------------

ENV HOST=0.0.0.0
ENV PORT=8080

ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=8080

ENV REBECCA_GATEWAY_ADDR=0.0.0.0:8080

ENV DATABASE=sqlite:////var/lib/rebecca/rebecca.db
ENV SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/rebecca/rebecca.db

ENV REBECCA_CONFIG_DIR=/var/lib/rebecca
ENV REBECCA_CERT_BASE=/var/lib/rebecca/certs

# Xray
ENV XRAY_LOCATION_ASSET=/usr/local/share/xray

# --------------------------------------------------
# Copy startup script
# --------------------------------------------------

COPY start.sh /start.sh

RUN chmod +x /start.sh

WORKDIR /opt/rebecca

EXPOSE 8080

ENTRYPOINT ["/bin/sh", "/start.sh"]