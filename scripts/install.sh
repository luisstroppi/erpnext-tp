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
BENCH_PYTHON="${ERP_TP_BENCH_PYTHON:-3.12}"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

trap 'printf "\n[ERROR] Installation failed at line %s. Re-run ./scripts/status.sh for diagnostics.\n" "$LINENO" >&2' ERR

[[ "$(uname -s)" == "Linux" ]] || die "This laboratory expects a Linux GitHub Codespace."
command -v sudo >/dev/null 2>&1 || die "sudo is required."

log "1/10 - Checking available resources"
df -h / | tail -n 1 || true
command -v free >/dev/null 2>&1 && free -h || true
warn "The build phase can temporarily consume considerably more RAM than normal execution."

log "2/10 - Installing minimal system dependencies"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  git curl ca-certificates build-essential pkg-config cron \
  python3 python3-dev python3-venv python3-pip \
  mariadb-server mariadb-client libmariadb-dev libmariadb-dev-compat \
  redis-server \
  libffi-dev libssl-dev libjpeg-dev zlib1g-dev \
  liblcms2-dev libwebp-dev libtiff-dev libopenjp2-7-dev \
  libldap2-dev libsasl2-dev
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
command -v crontab >/dev/null 2>&1 || die "crontab was not installed correctly."
ok "System packages installed"

log "3/10 - Configuring MariaDB for Frappe"
sudo tee /etc/mysql/mariadb.conf.d/99-frappe.cnf >/dev/null <<'EOF'
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
skip-name-resolve
bind-address = 127.0.0.1

[mysql]
default-character-set = utf8mb4
EOF
sudo service mariadb restart

if sudo mariadb -e 'SELECT 1' >/dev/null 2>&1; then
  sudo mariadb <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
ALTER USER 'root'@'127.0.0.1' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
elif mariadb -uroot -p"$DB_ROOT_PASSWORD" -e 'SELECT 1' >/dev/null 2>&1; then
  mariadb -uroot -p"$DB_ROOT_PASSWORD" <<SQL
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
ALTER USER 'root'@'127.0.0.1' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
  ok "MariaDB root password already configured"
else
  die "Unable to authenticate to MariaDB as root."
fi

mariadb -h127.0.0.1 -uroot -p"$DB_ROOT_PASSWORD" -e 'SELECT 1' >/dev/null 2>&1 || \
  die "MariaDB TCP authentication for root@127.0.0.1 is not working."
ok "MariaDB configured"

log "4/10 - Starting Redis"
sudo service redis-server start
redis-cli ping | grep -q PONG || die "Redis did not answer PONG."
ok "Redis is running"

log "5/10 - Installing Node.js, Yarn and Bench"
if ! command -v node >/dev/null 2>&1 || [[ "$(node -p 'Number(process.versions.node.split(`.`)[0])' 2>/dev/null || echo 0)" -lt 18 ]]; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
fi

if ! command -v yarn >/dev/null 2>&1; then
  sudo npm install --global yarn
fi

if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

uv python install "$BENCH_PYTHON"
BENCH_PYTHON_PATH="$(uv python find "$BENCH_PYTHON")"

if ! command -v bench >/dev/null 2>&1; then
  uv tool install --python "$BENCH_PYTHON_PATH" frappe-bench
fi
command -v bench >/dev/null 2>&1 || die "bench is not available on PATH."
node --version
yarn --version
"$BENCH_PYTHON_PATH" --version
bench --version
ok "Runtime toolchain installed"

log "6/10 - Creating Frappe bench (${FRAPPE_BRANCH})"
BENCH_VALID=false
if [[ -d "$BENCH_DIR/apps/frappe" && -x "$BENCH_DIR/env/bin/python" ]]; then
  if "$BENCH_DIR/env/bin/python" -c 'import click; import frappe' >/dev/null 2>&1; then
    BENCH_VALID=true
  fi
fi

if [[ "$BENCH_VALID" != true ]]; then
  if [[ -e "$BENCH_DIR" ]]; then
    warn "Incomplete or broken bench detected at $BENCH_DIR; rebuilding it."
    rm -rf "$BENCH_DIR"
  fi
  mkdir -p "$(dirname "$BENCH_DIR")"
  bench init --python "$BENCH_PYTHON_PATH" --frappe-branch "$FRAPPE_BRANCH" "$BENCH_DIR"
else
  ok "Existing Frappe bench is healthy; skipping bench init"
fi
cd "$BENCH_DIR"

[[ -x "env/bin/python" ]] || die "Bench virtualenv was not created correctly."
"env/bin/python" -c 'import click; import frappe' >/dev/null 2>&1 || \
  die "Bench virtualenv is incomplete: Frappe/Python dependencies cannot be imported."

log "7/10 - Creating or validating site ${SITE_NAME}"
SITE_CONFIG="sites/${SITE_NAME}/site_config.json"

if [[ ! -f "$SITE_CONFIG" ]]; then
  bench new-site "$SITE_NAME" \
    --mariadb-root-password "$DB_ROOT_PASSWORD" \
    --admin-password "$ADMIN_PASSWORD" \
    --mariadb-user-host-login-scope='%'
fi

if ! bench --site "$SITE_NAME" list-apps >/dev/null 2>&1; then
  warn "Site exists but cannot authenticate to MariaDB; repairing the site database user."

  readarray -t SITE_DB_VALUES < <("env/bin/python" - "$SITE_CONFIG" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    config = json.load(f)
print(config.get('db_name', ''))
print(config.get('db_password', ''))
PY
)

  SITE_DB_NAME="${SITE_DB_VALUES[0]:-}"
  SITE_DB_PASSWORD="${SITE_DB_VALUES[1]:-}"

  [[ "$SITE_DB_NAME" =~ ^[A-Za-z0-9_]+$ ]] || die "Unsafe or missing db_name in site_config.json."
  [[ -n "$SITE_DB_PASSWORD" ]] || die "Missing db_password in site_config.json."

  SITE_DB_NAME="$SITE_DB_NAME" \
  SITE_DB_PASSWORD="$SITE_DB_PASSWORD" \
  DB_ROOT_PASSWORD="$DB_ROOT_PASSWORD" \
  "env/bin/python" <<'PY'
import os
import pymysql

name = os.environ['SITE_DB_NAME']
password = os.environ['SITE_DB_PASSWORD']
root_password = os.environ['DB_ROOT_PASSWORD']

conn = pymysql.connect(host='127.0.0.1', user='root', password=root_password, autocommit=True)
try:
    with conn.cursor() as cur:
        # PyMySQL uses %-formatting for parameterized statements. A literal
        # wildcard host must therefore be written as %% when the query also
        # contains a %s placeholder.
        cur.execute(f"CREATE USER IF NOT EXISTS `{name}`@'%%' IDENTIFIED BY %s", (password,))
        cur.execute(f"ALTER USER `{name}`@'%%' IDENTIFIED BY %s", (password,))
        cur.execute(f"GRANT ALL PRIVILEGES ON `{name}`.* TO `{name}`@'%'")
        cur.execute("FLUSH PRIVILEGES")
finally:
    conn.close()
PY
fi

bench --site "$SITE_NAME" list-apps >/dev/null 2>&1 || \
  die "Site still cannot connect to MariaDB after repairing its database user."
ok "Site database connection verified"

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
Python:      $BENCH_PYTHON

Start ERPNext with:

  bash scripts/start.sh

Check the environment with:

  bash scripts/status.sh

IMPORTANT: these credentials and settings are for a disposable
teaching environment only. They are NOT suitable for production.
============================================================
EOF
