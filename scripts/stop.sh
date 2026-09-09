#!/usr/bin/env bash
set -Eeuo pipefail

# The normal way to stop `bench start` is Ctrl+C in its terminal.
# This helper also cleans up the bench Redis instances if they remain alive.
redis-cli -p 11000 shutdown >/dev/null 2>&1 || true
redis-cli -p 13000 shutdown >/dev/null 2>&1 || true
sudo service redis-server stop 2>/dev/null || true
sudo service mariadb stop 2>/dev/null || true

echo "MariaDB and Redis services stopped. If bench start is still running, stop it with Ctrl+C in its terminal."
