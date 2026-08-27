FROM golang:1.25-bookworm AS builder

RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone --depth 1 https://github.com/rebeccapanel/Rebecca.git .

# ==============================
# Build Dashboard
# ==============================

WORKDIR /build/dashboard

RUN npm ci

RUN npm run build

# ==============================
# Build Backend
# ==============================

WORKDIR /build

RUN go version

RUN bash scripts/build_binary.sh


# ==============================
# Runtime
# ==============================

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/rebecca

COPY --from=builder /build/dist ./dist
COPY --from=builder /build/dashboard/build ./dashboard/build

RUN mkdir -p /var/lib/rebecca

COPY start.sh /start.sh

RUN chmod +x /start.sh

ENV PORT=8080
ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=8080
ENV SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/rebecca/rebecca.db

EXPOSE 8080

CMD ["/start.sh"]