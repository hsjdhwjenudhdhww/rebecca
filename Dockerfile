FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ----------------------------------------------------------
# Base packages
# ----------------------------------------------------------

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    wget \
    unzip \
    openssl \
    jq \
    procps \
    iproute2 \
    net-tools \
    lsb-release \
    sudo \
    gnupg \
    git \
    nginx \
    tar \
    gzip \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------
# Directories
# ----------------------------------------------------------

RUN mkdir -p \
    /opt/rebecca \
    /var/lib/rebecca \
    /var/lib/rebecca/certs \
    /usr/local/bin

WORKDIR /opt

# ----------------------------------------------------------
# Install Rebecca DURING BUILD
# ----------------------------------------------------------

RUN curl -fsSL \
    https://raw.githubusercontent.com/rebeccapanel/Rebecca/master/scripts/rebecca/rebecca-binary.sh \
    -o /tmp/rebecca-install.sh \
    && chmod +x /tmp/rebecca-install.sh \
    && /tmp/rebecca-install.sh install --database sqlite \
    && rm -f /tmp/rebecca-install.sh

# ----------------------------------------------------------
# Verify Rebecca installation
# ----------------------------------------------------------

RUN test -f /opt/rebecca/bin/rebecca-server \
    || (echo "ERROR: Rebecca server binary not found" && \
        find /opt/rebecca -maxdepth 5 -type f -print && \
        exit 1)

RUN chmod +x /opt/rebecca/bin/rebecca-server

# ----------------------------------------------------------
# Install standalone Xray
# NO systemd
# ----------------------------------------------------------

ARG TARGETARCH

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) XRAY_ASSET="Xray-linux-64.zip" ;; \
        arm64) XRAY_ASSET="Xray-linux-arm64-v8a.zip" ;; \
        arm) XRAY_ASSET="Xray-linux-arm32-v7a.zip" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    TMP_DIR="$(mktemp -d)"; \
    curl -fL \
        --retry 5 \
        --retry-delay 2 \
        --connect-timeout 20 \
        "https://github.com/XTLS/Xray-core/releases/latest/download/${XRAY_ASSET}" \
        -o "${TMP_DIR}/xray.zip"; \
    unzip -oq "${TMP_DIR}/xray.zip" -d "${TMP_DIR}/xray"; \
    test -f "${TMP_DIR}/xray/xray"; \
    install -m 0755 "${TMP_DIR}/xray/xray" /usr/local/bin/xray; \
    rm -rf "${TMP_DIR}"

# ----------------------------------------------------------
# Verify Xray
# ----------------------------------------------------------

RUN /usr/local/bin/xray version

# ----------------------------------------------------------
# Runtime
# ----------------------------------------------------------

COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 8080
EXPOSE 5000

ENTRYPOINT ["/start.sh"]