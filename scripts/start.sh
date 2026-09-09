#!/usr/bin/env bash
set -Eeuo pipefail

BENCH_DIR="${ERP_TP_BENCH_DIR:-/workspaces/frappe-bench}"
SITE_NAME="${ERP_TP_SITE:-erp.localhost}"

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

[[ -d "$BENCH_DIR" ]] || { echo "Bench not found at $BENCH_DIR. Run ./scripts/install.sh first." >&2; exit 1; }
command -v bench >/dev/null 2>&1 || { echo "bench is not available on PATH." >&2; exit 1; }

sudo service mariadb start
mariadb-admin ping -uroot -p"${ERP_TP_DB_ROOT_PASSWORD:-root}" --silent || { echo "MariaDB is not responding." >&2; exit 1; }

# Do not start the system Redis service here. `bench start` launches the
# Redis Queue and Redis Cache instances defined by the bench Procfile/config.
cd "$BENCH_DIR"
bench use "$SITE_NAME" >/dev/null

echo "Starting ERPNext development environment..."
echo "Site: $SITE_NAME"
echo "Web port: 8000"
echo "Redis Queue: 11000"
echo "Redis Cache: 13000"
echo "Stop with Ctrl+C."
echo

exec bench start
