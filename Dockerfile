FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV HOST=0.0.0.0
ENV PORT=8080
ENV GATEWAY=0.0.0.0:8080
ENV DATABASE=sqlite:////var/lib/rebecca/rebecca.db

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    sqlite3 \
    unzip \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/rebecca /var/lib/rebecca

WORKDIR /opt/rebecca

# Rebecca source
RUN git clone --depth 1 \
    https://github.com/rebeccapanel/Rebecca.git \
    source

# --------------------------------------------------
# Xray Core
# --------------------------------------------------

RUN set -eux; \
    mkdir -p /tmp/xray-install /usr/local/bin /usr/local/share/xray; \
    curl -fL --retry 5 --retry-all-errors \
        "https://github.com/XTLS/Xray-core/releases/download/v26.3.27/Xray-linux-64.zip" \
        -o /tmp/xray-install/xray.zip; \
    unzip -o /tmp/xray-install/xray.zip \
        -d /tmp/xray-install/xray; \
    test -f /tmp/xray-install/xray/xray; \
    install -m 0755 \
        /tmp/xray-install/xray/xray \
        /usr/local/bin/xray; \
    if [ -f /tmp/xray-install/xray/geoip.dat ]; then \
        cp /tmp/xray-install/xray/geoip.dat \
           /usr/local/share/xray/geoip.dat; \
    fi; \
    if [ -f /tmp/xray-install/xray/geosite.dat ]; then \
        cp /tmp/xray-install/xray/geosite.dat \
           /usr/local/share/xray/geosite.dat; \
    fi; \
    /usr/local/bin/xray version; \
    rm -rf /tmp/xray-install

ENV XRAY_PATH=/usr/local/bin/xray
ENV XRAY_BIN=/usr/local/bin/xray
ENV XRAY_ASSET_PATH=/usr/local/share/xray

# --------------------------------------------------
# Build / locate Rebecca binaries
# --------------------------------------------------

WORKDIR /opt/rebecca/source

RUN if [ -f package.json ]; then \
        npm install && npm run build || true; \
    fi

WORKDIR /opt/rebecca

# Find binaries anywhere inside the cloned repository.
RUN set -eux; \
    CLI="$(find /opt/rebecca/source -type f -name 'rebecca-cli' -print -quit || true)"; \
    SERVER="$(find /opt/rebecca/source -type f -name 'rebecca-server' -print -quit || true)"; \
    echo "CLI=$CLI"; \
    echo "SERVER=$SERVER"; \
    test -n "$CLI"; \
    test -n "$SERVER"; \
    cp "$CLI" /opt/rebecca/rebecca-cli; \
    cp "$SERVER" /opt/rebecca/rebecca-server; \
    chmod +x /opt/rebecca/rebecca-cli /opt/rebecca/rebecca-server

# --------------------------------------------------
# Database
# --------------------------------------------------

RUN mkdir -p /var/lib/rebecca

# --------------------------------------------------
# Startup
# --------------------------------------------------

COPY start.sh /opt/rebecca/start.sh

RUN chmod +x /opt/rebecca/start.sh

EXPOSE 8080

ENTRYPOINT ["/opt/rebecca/start.sh"]