#!/usr/bin/env bash
set -u

BENCH_DIR="${ERP_TP_BENCH_DIR:-/workspaces/frappe-bench}"
SITE_NAME="${ERP_TP_SITE:-erp.localhost}"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

check() {
  local label="$1"
  shift
  printf '%-24s' "$label"
  if "$@" >/dev/null 2>&1; then
    echo "OK"
  else
    echo "NOT READY"
  fi
}

echo "ERPNext laboratory status"
echo "========================="
echo
check "MariaDB" sudo service mariadb status
check "Redis Queue :11000" redis-cli -p 11000 ping
check "Redis Cache :13000" redis-cli -p 13000 ping
check "Node.js" node --version
check "Yarn" yarn --version
check "Bench CLI" bench --version
check "Bench directory" test -d "$BENCH_DIR/apps/frappe"
check "Site config" test -f "$BENCH_DIR/sites/$SITE_NAME/site_config.json"
check "ERPNext source" test -d "$BENCH_DIR/apps/erpnext"

echo
if command -v node >/dev/null 2>&1; then echo "Node:  $(node --version)"; fi
if [[ -x "$BENCH_DIR/env/bin/python" ]]; then echo "Bench Python: $($BENCH_DIR/env/bin/python --version)"; fi
if command -v bench >/dev/null 2>&1; then echo "Bench: $(bench --version)"; fi

if [[ -d "$BENCH_DIR" ]] && command -v bench >/dev/null 2>&1; then
  echo
  echo "Installed apps on $SITE_NAME:"
  (cd "$BENCH_DIR" && bench --site "$SITE_NAME" list-apps) 2>/dev/null || echo "Unable to query site."
fi

echo
echo "Note: Redis Queue/Cache are expected to be NOT READY when bench start is not running."
echo
echo "Memory:"
free -h 2>/dev/null || true
echo
echo "Disk:"
df -h "$BENCH_DIR" 2>/dev/null || df -h /
