#!/usr/bin/env bash
set -e

MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root}"

if command -v mysql >/dev/null; then
  echo -e 'MySQL is already installed. Remove it first if you want to reinstall.\n'
  exit 1
fi

if command -v mariadb >/dev/null; then
  echo -e 'MariaDB is installed. Remove it first - MySQL and MariaDB conflict.\n'
  exit 1
fi

echo "Installing MySQL 8.4 from AUR..."
paru -S --needed --noconfirm mysql84 mysql-clients84

echo "Initializing data directory..."
sudo mysqld --initialize-insecure --user=mysql --basedir=/usr --datadir=/var/lib/mysql

echo "Symlinking local dev performance config..."
sudo ln -sf "$DOTFILES_REPO_HOME/config/mysql/local-dev.cnf" /etc/my.cnf.d/99-local-dev.cnf

echo "Overriding systemd ProtectHome to allow reading config from home directory..."
sudo mkdir -p /etc/systemd/system/mysqld.service.d
sudo tee /etc/systemd/system/mysqld.service.d/override.conf >/dev/null <<'EOF'
[Service]
ProtectHome=read-only
EOF
sudo systemctl daemon-reload

echo "Starting MySQL service..."
sudo systemctl enable --now mysqld

# Wait for MySQL to be ready, 2s should be fine.
sleep 2

# Set root password for local dev.
echo "Configuring root user..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD'; FLUSH PRIVILEGES;"

# Create ~/.my.cnf for passwordless local access.
cat >~/.my.cnf <<EOF
[client]
user = root
password = $MYSQL_ROOT_PASSWORD
host = localhost
port = 3306
socket = /run/mysqld/mysqld.sock

[mysql]
auto-rehash
prompt = "\\u@\\h [\\d]> "

[mysqldump]
quick
single-transaction
EOF
chmod 600 ~/.my.cnf

echo "MySQL $(mysql -e "SELECT VERSION();" -sN) installed and configured."
