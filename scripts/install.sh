#!/usr/bin/env bash
set -Eeuo pipefail

# ERPNext v15 teaching environment for GitHub Codespaces.
# Intentionally avoids Docker, nginx and production process managers.

FRAPPE_BRANCH="${FRAPPE_BRANCH:-version-15}"
ERPNEXT_BRANCH="${ERPNEXT_BRANCH:-version-15}"
BENCH_DIR="${ERP_TP_BENCH_DIR:-/workspaces/frappe-bench}"
SITE_NAME="${ERP_TP_SITE:-erp.localhost}"
DB_ROOT_PASSWORD="${ERP_TP_DB_ROOT_PASSWORD:-root}"
ADMIN_PASSWORD="${ERP_TP_ADMIN_PASSWORD:-admin}"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

trap 'printf "\n[ERROR] Installation failed at line %s. Re-run ./scripts/status.sh for diagnostics.\n" "$LINENO" >&2' ERR

if [[ "$(uname -s)" != "Linux" ]]; then
  die "This laboratory expects a Linux GitHub Codespace."
fi

if ! command -v sudo >/dev/null 2>&1; then
  die "sudo is required."
fi

log "1/10 - Checking available resources"
df -h / | tail -n 1 || true
if command -v free >/dev/null 2>&1; then free -h; fi
warn "The build phase can temporarily consume considerably more RAM than normal execution."

log "2/10 - Installing minimal system dependencies"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  git curl ca-certificates build-essential pkg-config \
  python3 python3-dev python3-venv python3-pip \
  mariadb-server mariadb-client libmariadb-dev libmariadb-dev-compat \
  redis-server \
  libffi-dev libssl-dev libjpeg-dev zlib1g-dev \
  liblcms2-dev libwebp-dev libtiff-dev libopenjp2-7-dev \
  libldap2-dev libsasl2-dev
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
ok "System packages installed"

log "3/10 - Configuring MariaDB for Frappe"
sudo tee /etc/mysql/mariadb.conf.d/99-frappe.cnf >/dev/null <<'EOF'
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
skip-name-resolve

[mysql]
default-character-set = utf8mb4
EOF
sudo service mariadb restart

# Debian/Ubuntu normally authenticates local root through unix_socket. Set a known
# password as well so bench new-site can run non-interactively in this disposable lab.
sudo mariadb <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
SQL
ok "MariaDB configured"

log "4/10 - Starting Redis"
sudo service redis-server start
redis-cli ping | grep -q PONG || die "Redis did not answer PONG."
ok "Redis is running"

log "5/10 - Installing Node.js, Yarn and Bench"
# Frappe v15 requires Node 18+. NodeSource 20 LTS is used to avoid distro-version drift.
if ! command -v node >/dev/null 2>&1 || [[ "$(node -p 'Number(process.versions.node.split(`.`)[0])' 2>/dev/null || echo 0)" -lt 18 ]]; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
fi

if ! command -v yarn >/dev/null 2>&1; then
  sudo npm install --global yarn
fi

# Install uv in the user's home, then install Bench as an isolated CLI tool.
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
if ! command -v bench >/dev/null 2>&1; then
  uv tool install frappe-bench
fi
command -v bench >/dev/null 2>&1 || die "bench is not available on PATH."
node --version
yarn --version
bench --version
ok "Runtime toolchain installed"

log "6/10 - Creating Frappe bench (${FRAPPE_BRANCH})"
if [[ ! -d "$BENCH_DIR/apps/frappe" ]]; then
  mkdir -p "$(dirname "$BENCH_DIR")"
  bench init --frappe-branch "$FRAPPE_BRANCH" "$BENCH_DIR"
else
  ok "Existing Frappe bench detected; skipping bench init"
fi
cd "$BENCH_DIR"

log "7/10 - Creating site ${SITE_NAME}"
if [[ ! -f "sites/${SITE_NAME}/site_config.json" ]]; then
  bench new-site "$SITE_NAME" \
    --mariadb-root-password "$DB_ROOT_PASSWORD" \
    --admin-password "$ADMIN_PASSWORD" \
    --no-mariadb-socket
else
  ok "Site already exists; skipping creation"
fi

log "8/10 - Downloading ERPNext (${ERPNEXT_BRANCH})"
if [[ ! -d "apps/erpnext" ]]; then
  bench get-app --branch "$ERPNEXT_BRANCH" erpnext https://github.com/frappe/erpnext
else
  ok "ERPNext source already exists; skipping download"
fi

log "9/10 - Installing ERPNext on ${SITE_NAME}"
if ! bench --site "$SITE_NAME" list-apps | grep -qx 'erpnext'; then
  bench --site "$SITE_NAME" install-app erpnext
else
  ok "ERPNext is already installed on the site"
fi

log "10/10 - Applying development configuration"
bench use "$SITE_NAME"
bench set-config -g developer_mode 1
bench set-config -g server_script_enabled 1
bench --site "$SITE_NAME" clear-cache

cat <<EOF

============================================================
 ERPNext v15 laboratory is ready
============================================================

Bench:       $BENCH_DIR
Site:        $SITE_NAME
User:        Administrator
Password:    $ADMIN_PASSWORD
Port:        8000

Start ERPNext with:

  ./scripts/start.sh

Check the environment with:

  ./scripts/status.sh

IMPORTANT: these credentials and settings are for a disposable
teaching environment only. They are NOT suitable for production.
============================================================
EOF
