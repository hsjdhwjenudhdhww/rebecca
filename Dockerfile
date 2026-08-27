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
    golang \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# ==========================================
# Directories
# ==========================================

RUN mkdir -p \
    /opt/rebecca \
    /var/lib/rebecca

WORKDIR /opt/rebecca

# ==========================================
# Clone Rebecca
# ==========================================

RUN git clone --depth 1 \
    https://github.com/rebeccapanel/Rebecca.git \
    source

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
# Build Rebecca Dashboard
# ==========================================

WORKDIR /opt/rebecca/source/dashboard

RUN npm ci

RUN VITE_BASE_API=/api/ \
    npm run build \
    -- --outDir=build \
    --assetsDir=statics

RUN cp ./build/index.html ./build/404.html

# ==========================================
# Build Rebecca Go binaries
# ==========================================

WORKDIR /opt/rebecca/source

RUN chmod +x scripts/build_binary.sh

RUN bash scripts/build_binary.sh

# ==========================================
# Verify binaries
# ==========================================

RUN test -x /opt/rebecca/source/dist/rebecca-cli

RUN test -x /opt/rebecca/source/dist/rebecca-server

# ==========================================
# Copy binaries to Rebecca directory
# ==========================================

RUN cp \
    /opt/rebecca/source/dist/rebecca-cli \
    /opt/rebecca/rebecca-cli

RUN cp \
    /opt/rebecca/source/dist/rebecca-server \
    /opt/rebecca/rebecca-server

RUN chmod +x \
    /opt/rebecca/rebecca-cli \
    /opt/rebecca/rebecca-server

# ==========================================
# Verify everything
# ==========================================

RUN echo "======================================" && \
    echo "Rebecca CLI:" && \
    /opt/rebecca/rebecca-cli --help && \
    echo "======================================" && \
    echo "Xray Core:" && \
    /usr/local/bin/xray version && \
    echo "======================================" && \
    ls -lh \
    /opt/rebecca/rebecca-cli \
    /opt/rebecca/rebecca-server \
    /usr/local/bin/xray

# ==========================================
# Environment
# ==========================================

ENV HOST=0.0.0.0
ENV PORT=8080

ENV DATABASE=sqlite:////var/lib/rebecca/rebecca.db

ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=8080

ENV REBECCA_GATEWAY_ADDR=0.0.0.0:8080

ENV PATH="/usr/local/bin:/opt/rebecca:${PATH}"

# ==========================================
# Start script
# ==========================================

COPY start.sh /opt/rebecca/start.sh

RUN chmod +x /opt/rebecca/start.sh

# Railway
EXPOSE 8080

ENTRYPOINT ["/opt/rebecca/start.sh"]