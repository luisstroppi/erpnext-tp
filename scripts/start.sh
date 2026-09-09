#!/usr/bin/env bash
set -Eeuo pipefail

BENCH_DIR="${ERP_TP_BENCH_DIR:-/workspaces/frappe-bench}"
SITE_NAME="${ERP_TP_SITE:-erp.localhost}"

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

[[ -d "$BENCH_DIR" ]] || { echo "Bench not found at $BENCH_DIR. Run ./scripts/install.sh first." >&2; exit 1; }
command -v bench >/dev/null 2>&1 || { echo "bench is not available on PATH." >&2; exit 1; }

sudo service mariadb start
sudo service redis-server start

redis-cli ping | grep -q PONG || { echo "Redis is not responding." >&2; exit 1; }
mariadb-admin ping -uroot -p"${ERP_TP_DB_ROOT_PASSWORD:-root}" --silent || { echo "MariaDB is not responding." >&2; exit 1; }

cd "$BENCH_DIR"
bench use "$SITE_NAME" >/dev/null

echo "Starting ERPNext development environment..."
echo "Site: $SITE_NAME"
echo "Port: 8000"
echo "Stop with Ctrl+C."
echo

exec bench start
