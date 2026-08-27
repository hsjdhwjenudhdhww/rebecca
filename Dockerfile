FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

ENV HOST=0.0.0.0
ENV PORT=8080
ENV GATEWAY=0.0.0.0:8080
ENV DATABASE=sqlite:////var/lib/rebecca/rebecca.db

ENV XRAY_PATH=/usr/local/bin/xray
ENV XRAY_BIN=/usr/local/bin/xray
ENV XRAY_ASSET_PATH=/usr/local/share/xray

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    unzip \
    sqlite3 \
    nodejs \
    npm \
    golang \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p \
    /opt/rebecca \
    /var/lib/rebecca \
    /usr/local/share/xray

WORKDIR /opt/rebecca

# ==========================================
# Rebecca source
# ==========================================

RUN git clone --depth 1 \
    https://github.com/rebeccapanel/Rebecca.git \
    source

# ==========================================
# Xray Core 26.3.27
# ==========================================

RUN set -eux; \
    mkdir -p /tmp/xray-install; \
    curl -fL --retry 5 --retry-all-errors \
        "https://github.com/XTLS/Xray-core/releases/download/v26.3.27/Xray-linux-64.zip" \
        -o /tmp/xray-install/xray.zip; \
    unzip -o \
        /tmp/xray-install/xray.zip \
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

# ==========================================
# Build dashboard
# ==========================================

WORKDIR /opt/rebecca/source/dashboard

RUN npm ci

RUN VITE_BASE_API=/api/ \
    npm run build -- \
    --outDir=build \
    --assetsDir=statics

RUN cp ./build/index.html ./build/404.html

# ==========================================
# Build Rebecca binaries
# ==========================================

WORKDIR /opt/rebecca/source

RUN chmod +x scripts/build_binary.sh

RUN ./scripts/build_binary.sh

# ==========================================
# Install binaries
# ==========================================

RUN set -eux; \
    test -f dist/rebecca-cli; \
    test -f dist/rebecca-server; \
    install -m 0755 \
        dist/rebecca-cli \
        /opt/rebecca/rebecca-cli; \
    install -m 0755 \
        dist/rebecca-server \
        /opt/rebecca/rebecca-server; \
    /opt/rebecca/rebecca-cli --help

# ==========================================
# Startup
# ==========================================

COPY start.sh /start.sh
COPY start.sh /opt/rebecca/start.sh

RUN chmod +x /start.sh /opt/rebecca/start.sh

WORKDIR /opt/rebecca

EXPOSE 8080

ENTRYPOINT ["/start.sh"]