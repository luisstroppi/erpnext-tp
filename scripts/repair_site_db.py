#!/usr/bin/env python3
import json
import os
import sys

import pymysql

bench_dir = os.environ.get("ERP_TP_BENCH_DIR", "/workspaces/frappe-bench")
site_name = os.environ.get("ERP_TP_SITE", "erp.localhost")
root_password = os.environ.get("ERP_TP_DB_ROOT_PASSWORD", "root")
config_path = os.path.join(bench_dir, "sites", site_name, "site_config.json")

with open(config_path, encoding="utf-8") as handle:
    config = json.load(handle)

name = config["db_name"]
password = config["db_password"]

if not name.replace("_", "").isalnum():
    raise SystemExit("Unsafe database name in site_config.json")

root = pymysql.connect(host="127.0.0.1", user="root", password=root_password, autocommit=True)
try:
    with root.cursor() as cur:
        for host in ("127.0.0.1", "localhost"):
            cur.execute(f"CREATE USER IF NOT EXISTS `{name}`@'{host}' IDENTIFIED BY %s", (password,))
            cur.execute(f"ALTER USER `{name}`@'{host}' IDENTIFIED BY %s", (password,))
            cur.execute(f"GRANT ALL PRIVILEGES ON `{name}`.* TO `{name}`@'{host}'")
        cur.execute(f"CREATE USER IF NOT EXISTS `{name}`@'%%' IDENTIFIED BY %s", (password,))
        cur.execute(f"ALTER USER `{name}`@'%%' IDENTIFIED BY %s", (password,))
        cur.execute(f"GRANT ALL PRIVILEGES ON `{name}`.* TO `{name}`@'%'")
        cur.execute("FLUSH PRIVILEGES")
finally:
    root.close()

site = pymysql.connect(host="127.0.0.1", user=name, password=password, database=name)
try:
    with site.cursor() as cur:
        cur.execute("SELECT 1")
        cur.fetchone()
finally:
    site.close()

print(f"Database credentials for {site_name} verified successfully.")
