FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ==========================================================
# System packages
# ==========================================================

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    wget \
    git \
    unzip \
    zip \
    openssl \
    jq \
    procps \
    iproute2 \
    net-tools \
    lsb-release \
    build-essential \
    pkg-config \
    nginx \
    golang \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# ==========================================================
# Clone Rebecca
# ==========================================================

WORKDIR /build

RUN git clone \
    --depth 1 \
    https://github.com/rebeccapanel/Rebecca.git \
    /build/Rebecca

WORKDIR /build/Rebecca

# ==========================================================
# Build dashboard
# ==========================================================

RUN cd dashboard \
    && npm ci \
    && VITE_BASE_API=/api/ npm run build \
        -- \
        --outDir=build \
        --assetsDir=statics \
    && cp build/index.html build/404.html

# ==========================================================
# Build Rebecca binaries
# ==========================================================

RUN bash scripts/build_binary.sh

# ==========================================================
# Verify build
# ==========================================================

RUN test -x /build/Rebecca/dist/rebecca-server \
    || ( \
        echo "==========================================" && \
        echo "ERROR: rebecca-server build failed" && \
        echo "==========================================" && \
        find /build/Rebecca \
            -maxdepth 5 \
            -type f \
            -name 'rebecca-*' \
            -print; \
        exit 1 \
    )

RUN test -x /build/Rebecca/dist/rebecca-cli \
    || ( \
        echo "ERROR: rebecca-cli build failed"; \
        exit 1; \
    )

# ==========================================================
# Runtime directory
# ==========================================================

RUN mkdir -p \
    /opt/rebecca \
    /var/lib/rebecca \
    /var/lib/rebecca/certs

# ==========================================================
# Copy Rebecca runtime
# ==========================================================

RUN cp -a /build/Rebecca/. /opt/rebecca/

RUN chmod +x \
    /opt/rebecca/dist/rebecca-server \
    /opt/rebecca/dist/rebecca-cli

# ==========================================================
# Xray standalone
# ==========================================================

ARG TARGETARCH

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) \
            XRAY_ASSET="Xray-linux-64.zip" \
            ;; \
        arm64) \
            XRAY_ASSET="Xray-linux-arm64-v8a.zip" \
            ;; \
        arm) \
            XRAY_ASSET="Xray-linux-arm32-v7a.zip" \
            ;; \
        *) \
            echo "Unsupported architecture: ${TARGETARCH}"; \
            exit 1 \
            ;; \
    esac; \
    TMP="$(mktemp -d)"; \
    curl -fL \
        --retry 5 \
        --retry-delay 2 \
        --connect-timeout 20 \
        "https://github.com/XTLS/Xray-core/releases/latest/download/${XRAY_ASSET}" \
        -o "${TMP}/xray.zip"; \
    unzip -oq \
        "${TMP}/xray.zip" \
        -d "${TMP}/xray"; \
    test -f "${TMP}/xray/xray"; \
    install -m 0755 \
        "${TMP}/xray/xray" \
        /usr/local/bin/xray; \
    rm -rf "${TMP}"

# ==========================================================
# Verify Xray
# ==========================================================

RUN /usr/local/bin/xray version

# ==========================================================
# Startup
# ==========================================================

COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 8080
EXPOSE 5000

ENTRYPOINT ["/start.sh"]