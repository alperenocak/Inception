#!/bin/bash
set -e

# Şifreleri secrets dosyalarından oku
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    # MariaDB'yi başlat (arka planda, kurulum için)
    mysqld_safe --skip-networking &

    until mysqladmin ping --silent; do
        sleep 1
    done

    # Veritabanı ve kullanıcıyı oluştur
    mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    # Arka plandaki mysqld'yi kapat
    mysqladmin -u root -p"${DB_ROOT_PASSWORD}" shutdown
fi

# Asıl prosesi başlat (PID 1)
exec mysqld_safe