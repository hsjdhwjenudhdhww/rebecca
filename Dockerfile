FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

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

WORKDIR /opt

RUN mkdir -p \
    /opt/rebecca \
    /var/lib/rebecca \
    /var/lib/rebecca/certs \
    /usr/local/bin

COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 8080
EXPOSE 5000

ENTRYPOINT ["/start.sh"]