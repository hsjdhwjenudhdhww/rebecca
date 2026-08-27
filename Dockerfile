FROM debian:trixie-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    sqlite3 \
    tar \
    gzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/rebecca

# ======================================
# Rebecca v0.1.4
# ======================================

RUN curl -fL \
    "https://github.com/rebeccapanel/Rebecca/releases/download/v0.1.4/rebecca-linux-amd64.tar.gz" \
    -o /tmp/rebecca.tar.gz \
    && tar -xzf /tmp/rebecca.tar.gz -C /opt/rebecca \
    && rm -f /tmp/rebecca.tar.gz

RUN chmod +x /opt/rebecca/rebecca-cli \
    /opt/rebecca/rebecca-server

RUN mkdir -p /var/lib/rebecca

COPY start.sh /start.sh

RUN chmod +x /start.sh

ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=8080
ENV SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/rebecca/rebecca.db

EXPOSE 8080

CMD ["/start.sh"]
