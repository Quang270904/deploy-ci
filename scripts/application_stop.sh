#!/bin/bash
# Application Stop Script

echo "Stopping application..."

# Stop PHP-FPM nếu đang chạy
if systemctl is-active --quiet php8.2-fpm; then
    echo "Stopping PHP-FPM..."
    systemctl stop php8.2-fpm
fi

# Stop Nginx nếu đang chạy
if systemctl is-active --quiet nginx; then
    echo "Stopping Nginx..."
    systemctl stop nginx
fi

# Stop Laravel queue workers nếu có
if [ -f /var/www/html/exment/artisan ]; then
    echo "Stopping Laravel queue workers..."
    cd /var/www/html/exment
    php artisan queue:restart || true
fi

echo "Application stopped successfully"
