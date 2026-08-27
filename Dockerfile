FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# Packages
# ============================================================

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    unzip \
    zip \
    sqlite3 \
    build-essential \
    pkg-config \
    nodejs \
    npm \
    golang \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Directories
# ============================================================

RUN mkdir -p \
    /opt/rebecca \
    /var/lib/rebecca \
    /usr/local/bin \
    /usr/local/share/xray \
    /etc/xray

WORKDIR /opt/rebecca

# ============================================================
# Rebecca source
# ============================================================

RUN git clone --depth 1 \
    https://github.com/rebeccapanel/Rebecca.git \
    source

# ============================================================
# Xray Core 26.3.27
# ============================================================

RUN set -eux; \
    mkdir -p /tmp/xray; \
    curl -fL --retry 10 --retry-all-errors \
      "https://github.com/XTLS/Xray-core/releases/download/v26.3.27/Xray-linux-64.zip" \
      -o /tmp/xray/xray.zip; \
    unzip -o /tmp/xray/xray.zip -d /tmp/xray; \
    test -f /tmp/xray/xray; \
    install -m 0755 \
      /tmp/xray/xray \
      /usr/local/bin/xray; \
    cp -f /tmp/xray/xray \
      /usr/local/share/xray/xray; \
    chmod 0755 /usr/local/share/xray/xray; \
    if [ -f /tmp/xray/geoip.dat ]; then \
      cp /tmp/xray/geoip.dat /usr/local/share/xray/geoip.dat; \
    fi; \
    if [ -f /tmp/xray/geosite.dat ]; then \
      cp /tmp/xray/geosite.dat /usr/local/share/xray/geosite.dat; \
    fi; \
    /usr/local/bin/xray version; \
    /usr/local/share/xray/xray version; \
    rm -rf /tmp/xray

# ============================================================
# Make compatibility paths
# ============================================================

RUN ln -sf /usr/local/bin/xray /usr/bin/xray

# ============================================================
# Build Rebecca
# ============================================================

WORKDIR /opt/rebecca/source

RUN set -eux; \
    if [ -d dashboard ]; then \
      cd dashboard; \
      npm ci; \
      VITE_BASE_API=/api/ npm run build \
        -- --outDir=build \
        --assetsDir=statics; \
      cp build/index.html build/404.html; \
    fi

WORKDIR /opt/rebecca/source

RUN set -eux; \
    chmod +x scripts/build_binary.sh; \
    bash scripts/build_binary.sh

# ============================================================
# Install Rebecca binaries
# ============================================================

RUN set -eux; \
    test -f dist/rebecca-cli; \
    test -f dist/rebecca-server; \
    cp dist/rebecca-cli /opt/rebecca/rebecca-cli; \
    cp dist/rebecca-server /opt/rebecca/rebecca-server; \
    chmod 0755 /opt/rebecca/rebecca-cli; \
    chmod 0755 /opt/rebecca/rebecca-server

# ============================================================
# Verify everything during BUILD
# ============================================================

RUN set -eux; \
    echo "========== XRAY =========="; \
    /usr/local/bin/xray version; \
    echo "========== REBECCA CLI =========="; \
    /opt/rebecca/rebecca-cli --help; \
    echo "========== REBECCA SERVER =========="; \
    /opt/rebecca/rebecca-server --help || true; \
    echo "========== FILES =========="; \
    ls -lh /usr/local/bin/xray; \
    ls -lh /usr/local/share/xray/xray; \
    ls -lh /opt/rebecca/rebecca-cli; \
    ls -lh /opt/rebecca/rebecca-server

# ============================================================
# Environment
# ============================================================

ENV HOST=0.0.0.0
ENV PORT=8080

ENV REBECCA_GATEWAY_ADDR=0.0.0.0:8080

ENV DATABASE=sqlite:////var/lib/rebecca/rebecca.db

# Required by Rebecca API runtime
ENV SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/rebecca/rebecca.db

ENV REBECCA_CONFIG_DIR=/var/lib/rebecca
ENV REBECCA_CERT_BASE=/var/lib/rebecca/certs

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray

# Important Xray paths
ENV XRAY_PATH=/usr/local/bin/xray
ENV XRAY_BINARY=/usr/local/bin/xray
ENV XRAY_EXECUTABLE=/usr/local/bin/xray

# ============================================================
# Startup
# ============================================================

COPY start.sh /start.sh

RUN chmod 0755 /start.sh

EXPOSE 8080

WORKDIR /opt/rebecca

ENTRYPOINT ["/bin/sh", "/start.sh"]