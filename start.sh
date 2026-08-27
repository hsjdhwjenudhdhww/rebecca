#!/bin/sh

set -eu

echo "======================================"
echo "        Rebecca Panel - Railway       "
echo "======================================"

PORT="${PORT:-8080}"

export UVICORN_HOST="0.0.0.0"
export UVICORN_PORT="$PORT"

export SQLALCHEMY_DATABASE_URL="${SQLALCHEMY_DATABASE_URL:-sqlite:////var/lib/rebecca/rebecca.db}"

mkdir -p /var/lib/rebecca

echo "[INFO] Listening on 0.0.0.0:${PORT}"
echo "[INFO] Database: ${SQLALCHEMY_DATABASE_URL}"

exec /opt/rebecca/dist/rebecca-server