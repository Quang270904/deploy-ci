#!/bin/bash
# Application Start Script

echo "Starting application..."

# Start PHP-FPM
echo "Starting PHP-FPM..."
systemctl start php8.2-fpm
systemctl enable php8.2-fpm

# Start Nginx
echo "Starting Nginx..."
systemctl start nginx
systemctl enable nginx

# Start Laravel queue workers (optional)
# Uncomment nếu dùng queue
# cd /var/www/html/exment
# php artisan queue:work --daemon &

echo "Application started successfully"
