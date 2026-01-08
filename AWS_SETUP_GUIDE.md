# AWS CodePipeline Setup Guide

## 📁 Files đã tạo

```
deploy-ci/
├── buildspec.yml              # CodeBuild configuration
├── appspec.yml               # CodeDeploy configuration
└── scripts/
    ├── application_stop.sh   # Stop services
    ├── before_install.sh     # Backup & cleanup
    ├── after_install.sh      # Setup Laravel
    ├── application_start.sh  # Start services
    └── validate_service.sh   # Health check
```

---

## 🚀 Bước 1: Push files lên GitHub & CodeCommit

```powershell
git add buildspec.yml appspec.yml scripts/
git commit -m "Add CodeBuild and CodeDeploy configuration"
git push origin main

# Tạo tag mới để trigger workflow
git tag prod-2026-01-08-final
git push origin prod-2026-01-08-final
```

---

## 🔧 Bước 2: Chuẩn bị EC2 Instance

### 2.1. Cài đặt CodeDeploy Agent trên EC2

SSH vào EC2 và chạy:

```bash
# Update system
sudo apt update

# Install CodeDeploy Agent
sudo apt install ruby-full wget -y
cd /tmp
wget https://aws-codedeploy-ap-northeast-1.s3.ap-northeast-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto

# Kiểm tra status
sudo service codedeploy-agent status
```

### 2.2. Cài đặt LEMP Stack

```bash
# Install Nginx
sudo apt install nginx -y

# Install PHP 8.2
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install php8.2-fpm php8.2-cli php8.2-mysql php8.2-xml php8.2-mbstring \
  php8.2-curl php8.2-zip php8.2-gd php8.2-bcmath -y

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs -y

# Tạo thư mục
sudo mkdir -p /var/www/html/exment
sudo chown -R www-data:www-data /var/www/html/exment
```

### 2.3. IAM Role cho EC2

EC2 cần IAM Role với các policies:
- `AmazonEC2RoleforAWSCodeDeploy`
- `AmazonS3ReadOnlyAccess` (để download artifacts)

**Gán IAM Role cho EC2:**
1. EC2 Console → chọn instance
2. Actions → Security → Modify IAM role
3. Chọn role đã tạo → Save

---

## ☁️ Bước 3: Setup trên AWS Console

### 3.1. Tạo CodeDeploy Application

1. **AWS Console → CodeDeploy → Applications → Create application**
   - Application name: `exment-app`
   - Compute platform: `EC2/On-premises`

2. **Create Deployment Group**
   - Deployment group name: `exment-production`
   - Service role: Chọn role có `AWSCodeDeployRole`
   - Deployment type: `In-place`
   - Environment configuration:
     - ✓ Amazon EC2 instances
     - Tag: `Name = exment-prod` (hoặc tag của EC2 bạn)
   - Deployment settings: `CodeDeployDefault.AllAtOnce`
   - Load balancer: Bỏ check (nếu không dùng)

### 3.2. Tạo CodeBuild Project

1. **AWS Console → CodeBuild → Create build project**
   - Project name: `exment-build`
   - Source provider: `AWS CodeCommit`
   - Repository: `demo-exment`
   - Branch: `master`
   - Environment:
     - Managed image: `Amazon Linux 2`
     - Runtime: `Standard`
     - Image: `aws/codebuild/amazonlinux2-x86_64-standard:5.0`
     - Service role: Auto-create hoặc chọn existing
   - Buildspec: `Use a buildspec file` (sẽ dùng buildspec.yml)
   - Artifacts:
     - Type: `Amazon S3`
     - Bucket name: Tạo bucket mới hoặc chọn existing (vd: `exment-build-artifacts`)
     - Name: `build-output.zip`
     - Packaging: `Zip`

### 3.3. Tạo CodePipeline

1. **AWS Console → CodePipeline → Create pipeline**

**Step 1: Pipeline settings**
   - Pipeline name: `exment-pipeline`
   - Service role: New service role (auto-create)

**Step 2: Source stage**
   - Source provider: `AWS CodeCommit`
   - Repository name: `demo-exment`
   - Branch name: `master`
   - Detection options: `AWS CodePipeline` (hoặc CloudWatch Events)

**Step 3: Build stage**
   - Build provider: `AWS CodeBuild`
   - Project name: `exment-build` (chọn project vừa tạo)

**Step 4: Deploy stage**
   - Deploy provider: `AWS CodeDeploy`
   - Application name: `exment-app`
   - Deployment group: `exment-production`

**Step 5: Review → Create pipeline**

---

## ✅ Bước 4: Test Pipeline

### Trigger Pipeline:

```powershell
# Push tag mới
git tag prod-2026-01-08-test
git push origin prod-2026-01-08-test
```

**Pipeline sẽ tự động chạy:**
1. ✓ Source: Pull code từ CodeCommit
2. ✓ Build: Chạy CodeBuild (composer install, npm build, cache)
3. ✓ Deploy: Deploy lên EC2 qua CodeDeploy

### Monitor:

- **CodePipeline:** Xem progress của từng stage
- **CodeBuild:** Xem build logs
- **CodeDeploy:** Xem deployment logs
- **EC2:** SSH vào xem `/var/www/html/exment`

---

## 🔍 Troubleshooting

### Lỗi CodeBuild:

```bash
# Xem logs trong CodeBuild console
# Kiểm tra buildspec.yml syntax
```

### Lỗi CodeDeploy:

```bash
# SSH vào EC2 và xem logs:
sudo cat /var/log/aws/codedeploy-agent/codedeploy-agent.log
sudo cat /opt/codedeploy-agent/deployment-root/deployment-logs/codedeploy-agent-deployments.log
```

### Script bị lỗi:

```bash
# Kiểm tra permissions
ls -la /var/www/html/exment/scripts/
# Phải có executable permission (755)
```

---

## 📝 Các điều chỉnh tùy chỉnh

### Thay đổi PHP version:

Sửa trong `buildspec.yml` và `scripts/*.sh`:
```yaml
runtime-versions:
  php: 8.3  # hoặc version khác
```

### Thay đổi deploy path:

Sửa trong `appspec.yml`:
```yaml
destination: /var/www/html/tên-app-khác
```

### Tự động chạy migration:

Uncomment trong `scripts/after_install.sh`:
```bash
php artisan migrate --force
```

---

## 🎯 Kết quả mong đợi

Sau khi setup xong:

1. **Push tag** `prod-*` lên GitHub
2. **GitHub Actions** push code lên CodeCommit
3. **CodePipeline** tự động trigger:
   - Build code (CodeBuild)
   - Deploy lên EC2 (CodeDeploy)
4. **Application** chạy trên EC2 tại `/var/www/html/exment`

---

**Nếu có vấn đề gì, báo mình nhé! 🚀**
