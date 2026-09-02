#!/bin/bash

set -e

DB_PASS=$(cat /run/secrets/db_password)
WP_ADMIN_PASS=$(cat /run/secrets/wp_admin_password)
WP_USER_PASS=$(cat /run/secrets/wp_user_password)

until mysqladmin ping -h mariadb -u"$MYSQL_USER" -p"$DB_PASS" --silent; do
    echo "MariaDB bekleniyor..."
    sleep 2
done

cd /var/www/wordpress

if [ ! -f wp-login.php ]; then
    wp core download --allow-root --locale=en_US

    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASS" \
        --dbhost="mariadb" \
        --allow-root

    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASS" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    wp user create \
        "$WP_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASS" \
        --allow-root
fi

exec /usr/sbin/php-fpm8.2 -F
