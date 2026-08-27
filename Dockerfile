FROM debian:trixie-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    nodejs \
    npm \
    golang \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Clone Rebecca
RUN git clone --depth 1 https://github.com/rebeccapanel/Rebecca.git .

# Build dashboard
WORKDIR /build/dashboard

RUN npm ci

RUN VITE_BASE_API=/api/ \
    npm run build -- \
    --outDir=build \
    --assetsDir=statics

RUN cp build/index.html build/404.html

# Build Go binaries
WORKDIR /build

RUN bash scripts/build_binary.sh


# ============================================================
# Runtime
# ============================================================

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/rebecca

# Copy built Rebecca
COPY --from=builder /build/dist/rebecca-server /opt/rebecca/rebecca-server
COPY --from=builder /build/dist/rebecca-cli /opt/rebecca/rebecca-cli

# Copy migrations/config/static files that may be required
COPY --from=builder /build /opt/rebecca/source

# Create data directory
RUN mkdir -p /var/lib/rebecca

RUN chmod +x \
    /opt/rebecca/rebecca-server \
    /opt/rebecca/rebecca-cli

COPY start.sh /start.sh

RUN sed -i 's/\r$//' /start.sh \
    && chmod +x /start.sh

ENV HOST=0.0.0.0
ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=8080
ENV REBECCA_GATEWAY_ADDR=0.0.0.0:8080

ENV SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/rebecca/rebecca.db

EXPOSE 8080

ENTRYPOINT ["/start.sh"]
