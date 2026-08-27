# syntax=docker/dockerfile:1

FROM golang:1.26-bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV CGO_ENABLED=1

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    nodejs \
    npm \
    bash \
    unzip \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Clone Rebecca source
RUN git clone --depth 1 https://github.com/rebeccapanel/Rebecca.git .

# ------------------------------------------------------------
# Build dashboard
# ------------------------------------------------------------

WORKDIR /build/dashboard

RUN npm ci

RUN VITE_BASE_API=/api/ \
    npm run build -- \
    --outDir=build \
    --assetsDir=statics

RUN cp ./build/index.html ./build/404.html

# ------------------------------------------------------------
# Build Rebecca Go binaries
# ------------------------------------------------------------

WORKDIR /build

RUN chmod +x scripts/build_binary.sh

RUN bash scripts/build_binary.sh

# Verify binaries really exist
RUN test -x /build/dist/rebecca-cli
RUN test -x /build/dist/rebecca-server

# Verify CLI is the Go CLI and contains migration command
RUN /build/dist/rebecca-cli --help

# ------------------------------------------------------------
# Download Xray
# ------------------------------------------------------------

ARG XRAY_VERSION=26.3.27

RUN mkdir -p /build/xray \
    && curl -fL --retry 5 --retry-all-errors \
    "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-64.zip" \
    -o /build/xray/xray.zip \
    && unzip -q /build/xray/xray.zip -d /build/xray \
    && test -f /build/xray/xray \
    && test -f /build/xray/geoip.dat \
    && test -f /build/xray/geosite.dat

# ------------------------------------------------------------
# Runtime
# ------------------------------------------------------------

FROM debian:bookworm-slim AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    sqlite3 \
    bash \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Directories
RUN mkdir -p \
    /opt/rebecca \
    /var/lib/rebecca \
    /usr/local/bin \
    /usr/local/share/xray

# Rebecca binaries
COPY --from=builder /build/dist/rebecca-cli /opt/rebecca/rebecca-cli
COPY --from=builder /build/dist/rebecca-server /opt/rebecca/rebecca-server

# Xray
COPY --from=builder /build/xray/xray /usr/local/bin/xray
COPY --from=builder /build/xray/geoip.dat /usr/local/share/xray/geoip.dat
COPY --from=builder /build/xray/geosite.dat /usr/local/share/xray/geosite.dat

RUN chmod +x \
    /opt/rebecca/rebecca-cli \
    /opt/rebecca/rebecca-server \
    /usr/local/bin/xray

# Stable PATH
ENV PATH="/opt/rebecca:/usr/local/bin:${PATH}"

# Rebecca configuration
ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=1234

ENV SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/rebecca/rebecca.db

ENV XRAY_EXECUTABLE_PATH=/usr/local/bin/xray
ENV XRAY_ASSETS_PATH=/usr/local/share/xray

# Railway uses this
ENV PORT=1234

WORKDIR /opt/rebecca

# Copy startup script
COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 1234

ENTRYPOINT ["/bin/bash", "/start.sh"]
