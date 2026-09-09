#!/usr/bin/env bash
set -Eeuo pipefail

# The normal way to stop `bench start` is Ctrl+C in its terminal.
# This helper stops the supporting services when the laboratory is finished.
sudo service redis-server stop 2>/dev/null || true
sudo service mariadb stop 2>/dev/null || true

echo "MariaDB and Redis stopped. If bench start is still running, stop it with Ctrl+C in its terminal."
