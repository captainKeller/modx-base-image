#!/bin/bash
set -e

MODX_CORE_CONFIG="/var/www/html/core/config/config.inc.php"
MYSQL_DATADIR="/var/lib/mysql"

# Default DB / admin settings (override via environment variables if needed)
: "${MODX_DB_NAME:=modx}"
: "${MODX_DB_USER:=modx}"
: "${MODX_DB_PASSWORD:=modx}"
: "${MODX_DB_PREFIX:=modx_}"

: "${MODX_ADMIN_USER:=admin}"
: "${MODX_ADMIN_PASS:=admin12345}"
: "${MODX_ADMIN_EMAIL:=admin@example.com}"

: "${MODX_HTTP_HOST:=localhost}"

echo "Ensuring /run/mysqld exists and has correct owner..."
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# Initialize MariaDB data directory if empty
if [ ! -d "${MYSQL_DATADIR}/mysql" ]; then
  echo "Initializing MariaDB data directory..."
  mysql_install_db --user=mysql --datadir="${MYSQL_DATADIR}" > /dev/null
fi

echo "Starting MariaDB..."
mysqld \
  --datadir="${MYSQL_DATADIR}" \
  --user=mysql \
  --socket=/run/mysqld/mysqld.sock \
  --pid-file=/run/mysqld/mysqld.pid &

echo "Waiting for MariaDB to be ready..."
# Use the same socket path as mysqld
until mysql -u root --socket=/run/mysqld/mysqld.sock -e "SELECT 1" >/dev/null 2>&1; do
  echo "Still waiting for MariaDB..."
  sleep 2
done

echo "MariaDB is up."

# Create MODX database and user if not existing
mysql -u root --socket=/run/mysqld/mysqld.sock -e "CREATE DATABASE IF NOT EXISTS \`${MODX_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root --socket=/run/mysqld/mysqld.sock -e "CREATE USER IF NOT EXISTS '${MODX_DB_USER}'@'localhost' IDENTIFIED BY '${MODX_DB_PASSWORD}';"
mysql -u root --socket=/run/mysqld/mysqld.sock -e "GRANT ALL PRIVILEGES ON \`${MODX_DB_NAME}\`.* TO '${MODX_DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

# Only run MODX installer if not already installed
if [ ! -f "$MODX_CORE_CONFIG" ]; then
  echo "MODX not installed yet – running CLI installer..."

  mkdir -p /var/www/html/setup

  cat > /var/www/html/setup/config.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<modx>
  <database_type>mysql</database_type>
  <database_server>127.0.0.1</database_server>
  <database>${MODX_DB_NAME}</database>
  <database_user>${MODX_DB_USER}</database_user>
  <database_password>${MODX_DB_PASSWORD}</database_password>
  <table_prefix>${MODX_DB_PREFIX}</table_prefix>

  <database_connection_charset>utf8mb4</database_connection_charset>
  <database_charset>utf8mb4</database_charset>
  <database_collation>utf8mb4_unicode_ci</database_collation>

  <language>en</language>

  <cmsadmin>${MODX_ADMIN_USER}</cmsadmin>
  <cmspassword>${MODX_ADMIN_PASS}</cmspassword>
  <cmsadminemail>${MODX_ADMIN_EMAIL}</cmsadminemail>

  <context_mgr_path>/var/www/html/manager/</context_mgr_path>
  <context_mgr_url>/manager/</context_mgr_url>
  <context_connectors_path>/var/www/html/connectors/</context_connectors_path>
  <context_connectors_url>/connectors/</context_connectors_url>
  <context_web_path>/var/www/html/</context_web_path>
  <context_web_url>/</context_web_url>

  <assets_path>/var/www/html/assets/</assets_path>
  <assets_url>/assets/</assets_url>

  <core_path>/var/www/html/core/</core_path>
  <http_host>${MODX_HTTP_HOST}</http_host>
  <https_port>443</https_port>

  <remove_setup_directory>1</remove_setup_directory>
</modx>
EOF

  php /var/www/html/setup/index.php --installmode=new --config=/var/www/html/setup/config.xml

  echo "MODX installation finished."
else
  echo "MODX already installed – skipping installer."
fi

echo "Starting Apache..."
exec apache2-foreground
