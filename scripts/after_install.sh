#!/bin/bash
# After Install Script

echo "Running after install tasks..."

cd /var/www/html/exment

# Restore .env file nếu có
if [ -f /tmp/.env.backup ]; then
    echo "Restoring .env file..."
    cp /tmp/.env.backup .env
    rm /tmp/.env.backup
fi

# Tạo .env từ .env.example nếu chưa có
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    php artisan key:generate
fi

# Set permissions
echo "Setting permissions..."
chown -R www-data:www-data /var/www/html/exment
chmod -R 755 /var/www/html/exment
chmod -R 775 /var/www/html/exment/storage
chmod -R 775 /var/www/html/exment/bootstrap/cache

# Clear Laravel cache
echo "Clearing Laravel caches..."
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Run migrations (optional - bỏ comment nếu muốn tự động migrate)
# php artisan migrate --force

# Optimize Laravel
echo "Optimizing Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Link storage nếu chưa có
if [ ! -L /var/www/html/exment/public/storage ]; then
    echo "Creating storage link..."
    php artisan storage:link
fi

echo "After install completed"
