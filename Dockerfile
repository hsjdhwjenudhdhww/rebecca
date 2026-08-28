FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    unzip \
    openssl \
    bash \
    jq \
    procps \
    iproute2 \
    net-tools \
    lsb-release \
    sudo \
    gnupg \
    git \
    nginx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 8080
EXPOSE 5000

ENTRYPOINT ["/start.sh"]