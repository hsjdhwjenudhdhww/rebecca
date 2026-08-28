FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
        openssl \
        bash \
        jq \
        procps \
        iproute2 \
        net-tools \
        nginx \
    && rm -rf /var/lib/apt/lists/*

# Rebecca master
RUN curl -fsSL \
    https://raw.githubusercontent.com/rebeccapanel/Rebecca/master/scripts/rebecca/rebecca-binary.sh \
    | bash -s -- install --database sqlite

# Rebecca node runtime
RUN curl -fsSL \
    https://raw.githubusercontent.com/rebeccapanel/Rebecca/master/scripts/rebecca/rebecca-node-binary.sh \
    | bash -s -- install

# Xray core
RUN curl -fsSL \
    https://github.com/XTLS/Xray-install/raw/main/install-release.sh \
    | bash -s -- install

COPY start.sh /start.sh
RUN chmod +x /start.sh

# Rebecca master
EXPOSE 8080

# Rebecca node
EXPOSE 5000

ENTRYPOINT ["/start.sh"]