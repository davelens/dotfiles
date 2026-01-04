#!/usr/bin/env bash
set -e

MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root}"

if command -v mariadb >/dev/null; then
  echo -e 'MariaDB is already installed. Run this to remove it:\n'
  echo '  utility arch mariadb-uninstall'
  exit 1
fi

echo "Installing MariaDB LTS..."
sudo pacman -S --needed --noconfirm mariadb-lts

echo "Initializing data directory..."
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

echo "Symlinking local dev performance config..."
sudo ln -sf "$DOTFILES_REPO_HOME/config/mariadb/local-dev.cnf" /etc/my.cnf.d/99-local-dev.cnf

echo "Overriding systemd ProtectHome to allow reading config from home directory..."
sudo mkdir -p /etc/systemd/system/mariadb.service.d
sudo tee /etc/systemd/system/mariadb.service.d/override.conf >/dev/null <<'EOF'
[Service]
ProtectHome=read-only
EOF
sudo systemctl daemon-reload

echo "Starting MariaDB service..."
sudo systemctl enable --now mariadb

# Wait for MariaDB to be ready, 2s should be fine.
sleep 2

# Override default root password so we can have root:root for local dev.
echo "Configuring root user..."
sudo mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD'; FLUSH PRIVILEGES;"

# Create ~/.my.cnf for passwordless local access.
cat >~/.my.cnf <<EOF
[client]
user = root
password = $MYSQL_ROOT_PASSWORD
host = localhost
port = 3306
socket = /run/mysqld/mysqld.sock
skip-ssl

[mysql]
auto-rehash
prompt = "\\u@\\h [\\d]> "

[mysqldump]
quick
single-transaction
EOF
chmod 600 ~/.my.cnf

echo "MariaDB $(mariadb -e "SELECT VERSION();" -sN) installed and configured."
