#!/bin/bash
# Validate Service Script

echo "Validating deployment..."

# Kiểm tra PHP-FPM
if ! systemctl is-active --quiet php8.2-fpm; then
    echo "ERROR: PHP-FPM is not running"
    exit 1
fi
echo "✓ PHP-FPM is running"

# Kiểm tra Nginx
if ! systemctl is-active --quiet nginx; then
    echo "ERROR: Nginx is not running"
    exit 1
fi
echo "✓ Nginx is running"

# Kiểm tra Laravel app
if [ -f /var/www/html/exment/artisan ]; then
    cd /var/www/html/exment
    # Test artisan command
    if php artisan --version > /dev/null 2>&1; then
        echo "✓ Laravel application is working"
    else
        echo "ERROR: Laravel application failed"
        exit 1
    fi
else
    echo "ERROR: artisan file not found"
    exit 1
fi

# Kiểm tra HTTP response (optional)
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
if [ "$HTTP_STATUS" == "200" ] || [ "$HTTP_STATUS" == "302" ]; then
    echo "✓ HTTP service is responding (Status: $HTTP_STATUS)"
else
    echo "WARNING: HTTP status is $HTTP_STATUS"
fi

echo "Deployment validation completed successfully!"
exit 0
