#!/bin/sh
set -e

# Wait for MySQL to be ready
echo "Waiting for MySQL at $DB_HOST..."
until nc -z $DB_HOST 3306; do
  printf "."
  sleep 1
done
echo "MySQL is up and running!"

MAGENTO_ROOT=/var/www/html

# Check if Magento is already installed (env.php exists)
if [ ! -f "$MAGENTO_ROOT/app/etc/env.php" ]; then
    echo "Magento not detected. Running installation..."
    php "$MAGENTO_ROOT/bin/magento" "$MAGENTO_INSTALL_COMMAND" \
        --base-url="$MAGENTO_BASE_URL" \
        --db-host="$DB_HOST" \
        --db-name="$DB_NAME" \
        --db-user="$DB_USER" \
        --db-password="$DB_PASSWORD" \
        --backend-frontname="$MAGENTO_BACKEND_FRONTNAME" \
        --admin-firstname="Admin" \
        --admin-lastname="User" \
        --admin-email="admin@ymail.com" \
        --admin-user="admin" \
        --admin-password="Admin@1234" \
        --language="en_US" \
        --currency="USD" \
        --timezone="Asia/Kolkata" \
        --use-rewrites="1" \
        --crypt-key="$MAGENTO_CRYPT_KEY" \
        --cleanup-database \
        --use-sample-data="no" # Change to "yes" if you want sample data

    echo "Magento installation complete."
else
    echo "Magento detected. Running setup:upgrade and compilation..."
fi

# Always run upgrade, compile, and static content deploy to ensure consistency
php "$MAGENTO_ROOT/bin/magento" setup:upgrade --keep-generated
php "$MAGENTO_ROOT/bin/magento" setup:di:compile
php "$MAGENTO_ROOT/bin/magento" setup:static-content:deploy -f en_US # Adjust locale if needed
php "$MAGENTO_ROOT/bin/magento" cache:flush

echo "Magento setup complete. Starting PHP-FPM..."
exec "$@"