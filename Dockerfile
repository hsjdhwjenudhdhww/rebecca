FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    sqlite3 \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/rebecca

# Clone Rebecca source
RUN git clone --depth 1 https://github.com/rebeccapanel/Rebecca.git source

WORKDIR /opt/rebecca/source

# Install/build frontend if package.json exists
RUN if [ -f package.json ]; then \
        npm install && npm run build || true; \
    fi

# Find Rebecca binaries
WORKDIR /opt/rebecca

RUN find /opt/rebecca/source -type f -name "rebecca-cli" \
    -exec cp {} /opt/rebecca/rebecca-cli \; || true

RUN find /opt/rebecca/source -type f -name "rebecca-server" \
    -exec cp {} /opt/rebecca/rebecca-server \; || true

RUN chmod +x \
    /opt/rebecca/rebecca-cli \
    /opt/rebecca/rebecca-server

# Database directory
RUN mkdir -p /var/lib/rebecca

COPY start.sh /opt/rebecca/start.sh

RUN chmod +x /opt/rebecca/start.sh

EXPOSE 8080

ENTRYPOINT ["/opt/rebecca/start.sh"]
