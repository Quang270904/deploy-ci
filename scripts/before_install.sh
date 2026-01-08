#!/bin/bash
# Before Install Script

echo "Running before install tasks..."

# Backup thư mục cũ nếu tồn tại
if [ -d /var/www/html/exment ]; then
    echo "Backing up existing application..."
    BACKUP_DIR="/var/www/backups/exment_$(date +%Y%m%d_%H%M%S)"
    mkdir -p /var/www/backups
    cp -r /var/www/html/exment "$BACKUP_DIR"
    echo "Backup created at $BACKUP_DIR"
    
    # Giữ lại .env file
    if [ -f /var/www/html/exment/.env ]; then
        cp /var/www/html/exment/.env /tmp/.env.backup
        echo ".env file backed up"
    fi
    
    # Xóa thư mục cũ (trừ storage)
    find /var/www/html/exment -mindepth 1 -maxdepth 1 ! -name 'storage' -exec rm -rf {} +
else
    echo "No existing application found. Creating directory..."
    mkdir -p /var/www/html/exment
fi

echo "Before install completed"
