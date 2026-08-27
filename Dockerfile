FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# Dependencies
# ============================================================

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    unzip \
    sqlite3 \
    bash \
    procps \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Directories
# ============================================================

RUN mkdir -p \
    /opt/rebecca \
    /var/lib/rebecca \
    /usr/local/share/xray

# ============================================================
# Railway / Rebecca configuration
# ============================================================

ENV HOST=0.0.0.0
ENV PORT=8080

ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=8080

ENV REBECCA_GATEWAY_ADDR=0.0.0.0:8080

ENV DATABASE=sqlite:////var/lib/rebecca/rebecca.db

# Rebecca Go runtime requires this variable
ENV SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/rebecca/rebecca.db

ENV REBECCA_CONFIG_DIR=/var/lib/rebecca
ENV REBECCA_CERT_BASE=/var/lib/rebecca/certs

# Xray paths used by Rebecca
ENV XRAY_EXECUTABLE_PATH=/usr/local/bin/xray
ENV XRAY_ASSETS_PATH=/usr/local/share/xray

# ============================================================
# Install official Rebecca binary
# ============================================================

RUN set -eux; \
    curl -fsSL \
    https://raw.githubusercontent.com/rebeccapanel/Rebecca/master/scripts/rebecca/rebecca-binary.sh \
    -o /tmp/rebecca-binary.sh; \
    chmod +x /tmp/rebecca-binary.sh; \
    /tmp/rebecca-binary.sh install; \
    rm -f /tmp/rebecca-binary.sh

# ============================================================
# Verify Rebecca installation
# ============================================================

RUN set -eux; \
    echo "========== /opt/rebecca =========="; \
    ls -lah /opt/rebecca; \
    echo "========== Rebecca CLI =========="; \
    if [ -x /usr/local/bin/rebecca ]; then \
        /usr/local/bin/rebecca --help; \
    elif [ -x /opt/rebecca/rebecca ]; then \
        /opt/rebecca/rebecca --help; \
    else \
        find /opt/rebecca /usr/local/bin \
        -maxdepth 2 \
        -type f \
        -name '*rebecca*' \
        -ls; \
    fi

# ============================================================
# Install Xray through Rebecca's own installation mechanism
# ============================================================

RUN set -eux; \
    if [ -x /usr/local/bin/xray ]; then \
        echo "Xray already installed by Rebecca installer"; \
    else \
        echo "Installing Xray Core..."; \
        curl -fsSL \
        https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh \
        -o /tmp/xray-install.sh; \
        chmod +x /tmp/xray-install.sh; \
        /tmp/xray-install.sh install; \
        rm -f /tmp/xray-install.sh; \
    fi; \
    test -x /usr/local/bin/xray; \
    /usr/local/bin/xray version

# ============================================================
# Create compatibility symlinks if necessary
# ============================================================

RUN set -eux; \
    mkdir -p /usr/local/share/xray; \
    if [ -f /usr/local/share/xray/geoip.dat ]; then \
        echo "geoip.dat found"; \
    fi; \
    if [ -f /usr/local/share/xray/geosite.dat ]; then \
        echo "geosite.dat found"; \
    fi

# ============================================================
# Startup
# ============================================================

COPY start.sh /start.sh

RUN chmod +x /start.sh

WORKDIR /opt/rebecca

EXPOSE 8080

ENTRYPOINT ["/bin/bash", "/start.sh"]