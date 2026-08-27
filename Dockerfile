FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    unzip \
    sqlite3 \
    bash \
    procps \
    git \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# Directories
# --------------------------------------------------

RUN mkdir -p \
    /opt/rebecca \
    /var/lib/rebecca \
    /usr/local/bin \
    /usr/local/share/xray

# --------------------------------------------------
# Install Xray
# --------------------------------------------------

RUN set -eux; \
    mkdir -p /tmp/xray; \
    curl -fL --retry 5 --retry-all-errors \
    https://github.com/XTLS/Xray-install/releases/latest/download/Xray-linux-64.zip \
    -o /tmp/xray/xray.zip; \
    unzip -o /tmp/xray/xray.zip -d /tmp/xray; \
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

# --------------------------------------------------
# Install Rebecca
# --------------------------------------------------

RUN set -eux; \
    mkdir -p /tmp/rebecca; \
    curl -fL --retry 5 --retry-all-errors \
    "https://github.com/rebeccapanel/Rebecca/releases/latest/download/rebecca-linux-amd64.tar.gz" \
    -o /tmp/rebecca/rebecca.tar.gz; \
    tar -xzf /tmp/rebecca/rebecca.tar.gz -C /tmp/rebecca; \
    echo "=== Rebecca release files ==="; \
    find /tmp/rebecca -maxdepth 4 -type f -print; \
    CLI="$(find /tmp/rebecca -type f -name 'rebecca-cli' -print -quit)"; \
    SERVER="$(find /tmp/rebecca -type f -name 'rebecca-server' -print -quit)"; \
    test -n "$CLI"; \
    test -n "$SERVER"; \
    install -m 0755 "$CLI" /opt/rebecca/rebecca-cli; \
    install -m 0755 "$SERVER" /opt/rebecca/rebecca-server; \
    ln -sf /opt/rebecca/rebecca-cli /usr/local/bin/rebecca-cli; \
    ln -sf /opt/rebecca/rebecca-server /usr/local/bin/rebecca-server; \
    /opt/rebecca/rebecca-cli --help; \
    rm -rf /tmp/rebecca

# --------------------------------------------------
# Start script
# --------------------------------------------------

COPY start.sh /start.sh

RUN chmod +x /start.sh

WORKDIR /opt/rebecca

EXPOSE 1234

ENTRYPOINT ["/bin/bash", "/start.sh"]
