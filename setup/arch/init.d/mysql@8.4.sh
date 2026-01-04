#!/usr/bin/env bash
set -e

MYSQL_CONFIG_DIR="$DOTFILES_REPO_HOME/config/mysql/docker"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root}"

if ! command -v docker >/dev/null; then
  echo "Docker is not installed. Install it first."
  exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -q '^mysql84$'; then
  echo "MySQL 8.4 container already exists. To recreate:"
  echo "  docker rm -f mysql84"
  echo "  # Then run this script again"
  exit 1
fi

echo "Starting MySQL 8.4 container..."
docker compose -f "$MYSQL_CONFIG_DIR/docker-compose.yml" up -d

echo "Waiting for MySQL to be ready..."
until docker exec mysql84 mysqladmin ping -h localhost -uroot -proot --silent 2>/dev/null; do
  sleep 1
done

# Create ~/.my.cnf for passwordless local access via TCP.
cat >~/.my.cnf <<EOF
[client]
user = root
password = $MYSQL_ROOT_PASSWORD
host = 127.0.0.1
port = 3306
protocol = tcp

[mysql]
auto-rehash
prompt = "\\u@\\h [\\d]> "

[mysqldump]
quick
single-transaction
EOF
chmod 600 ~/.my.cnf

echo "MySQL $(docker exec mysql84 mysql -uroot -proot -sNe "SELECT VERSION();" 2>/dev/null) is ready."
echo
echo "Commands:"
echo "  Start:  docker compose -f $MYSQL_CONFIG_DIR/docker-compose.yml up -d"
echo "  Stop:   docker compose -f $MYSQL_CONFIG_DIR/docker-compose.yml down"
echo "  Shell:  mysql (uses ~/.my.cnf)"
