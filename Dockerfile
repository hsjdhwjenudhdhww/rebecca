FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# ==========================================
# System dependencies
# ==========================================

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    sqlite3 \
    nodejs \
    npm \
    unzip \
    tar \
    && rm -rf /var/lib/apt/lists/*

# ==========================================
# Directories
# ==========================================

RUN mkdir -p \
    /opt/rebecca \
    /var/lib/rebecca \
    /usr/local/share/xray

WORKDIR /opt/rebecca

# ==========================================
# Clone Rebecca
# ==========================================

RUN git clone --depth 1 \
    https://github.com/rebeccapanel/Rebecca.git \
    source

# ==========================================
# Build frontend if package.json exists
# ==========================================

WORKDIR /opt/rebecca/source

RUN if [ -f package.json ]; then \
        npm install && npm run build || true; \
    fi

WORKDIR /opt/rebecca

# ==========================================
# Find Rebecca binaries
# ==========================================

RUN CLI="$(find /opt/rebecca/source \
        -type f \
        -name 'rebecca-cli' \
        -print -quit)" && \
    SERVER="$(find /opt/rebecca/source \
        -type f \
        -name 'rebecca-server' \
        -print -quit)" && \
    test -n "$CLI" && \
    test -n "$SERVER" && \
    cp "$CLI" /opt/rebecca/rebecca-cli && \
    cp "$SERVER" /opt/rebecca/rebecca-server

RUN chmod +x \
    /opt/rebecca/rebecca-cli \
    /opt/rebecca/rebecca-server

# ==========================================
# Install Xray Core
# ==========================================

RUN set -eux; \
    curl -L \
    https://github.com/XTLS/Xray-install/raw/main/install-release.sh \
    | bash -s -- install; \
    test -x /usr/local/bin/xray; \
    /usr/local/bin/xray version

# ==========================================
# Make sure Xray is available in PATH
# ==========================================

ENV PATH="/usr/local/bin:${PATH}"

# ==========================================
# Verify Rebecca + Xray
# ==========================================

RUN echo "===== Rebecca CLI =====" && \
    /opt/rebecca/rebecca-cli --help && \
    echo "===== Xray =====" && \
    /usr/local/bin/xray version && \
    echo "===== Files =====" && \
    ls -lh /opt/rebecca/rebecca-cli \
           /opt/rebecca/rebecca-server \
           /usr/local/bin/xray

# ==========================================
# Environment
# ==========================================

ENV HOST=0.0.0.0
ENV PORT=8080
ENV DATABASE=sqlite:////var/lib/rebecca/rebecca.db

# ==========================================
# Start script
# ==========================================

COPY start.sh /opt/rebecca/start.sh

RUN chmod +x /opt/rebecca/start.sh

# Railway HTTP port
EXPOSE 8080

ENTRYPOINT ["/opt/rebecca/start.sh"]