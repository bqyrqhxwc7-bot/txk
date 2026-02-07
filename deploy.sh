#!/bin/bash

# 桶管理系统一键部署脚本（真正的一键部署版本）
# 适用于Ubuntu 20.04 LTS及以上版本
# 自动克隆GitHub仓库
# 已修复sharp编译依赖问题

set -e

echo "🚀 开始真正的一键部署桶管理系统..."

# 检查root权限
if [ "$EUID" -ne 0 ]; then
  echo "请以root用户运行此脚本"
  exit 1
fi

# 获取当前目录（用于后续操作）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 安装基础工具
echo "🔧 安装基础工具..."
apt update && apt upgrade -y
apt install -y git curl wget sudo

# 安装Node.js 18 LTS
echo "📦 安装Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs

# 安装MongoDB 6.0（修复apt-key弃用问题）
echo "💾 安装MongoDB..."
# 创建密钥环目录
mkdir -p /etc/apt/keyrings

# 下载并安装GPG密钥（新方法）
curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | \
   sudo gpg --dearmor -o /etc/apt/keyrings/mongodb-server-6.0.gpg

# 添加MongoDB仓库源
echo "deb [ arch=amd64, signed-by=/etc/apt/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# 更新包列表并安装MongoDB
apt update
apt install -y mongodb-org

# 启动MongoDB服务
echo "🔧 启动MongoDB..."
systemctl start mongod
systemctl enable mongod

# 创建应用目录并处理已存在目录的情况
echo "📁 创建应用目录..."
APP_DIR="/var/www/barrel-management"
mkdir -p $APP_DIR
cd $APP_DIR

# 检查目录是否为空，如果非空则清理
if [ "$(ls -A $APP_DIR)" ]; then
    echo "⚠️  目录 '$APP_DIR' 已存在且非空，正在清理..."
    # 删除除隐藏文件外的所有内容（保留.gitignore等配置文件）
    find $APP_DIR -maxdepth 1 ! -name ".gitignore" ! -name ".env" ! -name ".dockerignore" -type f -delete
    find $APP_DIR -maxdepth 1 ! -name ".git" ! -name ".gitignore" ! -name ".env" ! -name ".dockerignore" -type d -exec rm -rf {} \;
    echo "✅ 目录清理完成"
fi

# 自动克隆GitHub仓库（使用标准URL格式）
echo "📥 自动克隆GitHub项目..."
git clone https://github.com/bqyrqhxwc7-bot/txk.git .
echo "✅ 项目代码已自动克隆完成"

# 安装sharp库所需的系统依赖
echo "🛠️ 安装sharp库系统依赖..."
apt install -y \
    libvips-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libgif-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libwebp-dev \
    libxml2-dev \
    libglib2.0-dev \
    libgobject-2.0-dev

# 安装应用依赖
echo "🧩 安装依赖..."
# 设置环境变量避免sharp编译问题
export SHARP_IGNORE_GLOBAL_LIBVIPS=1
npm install --production

# 创建环境变量配置文件
echo "⚙️ 创建环境配置..."
cat > .env << EOF
# 应用配置
PORT=3000
NODE_ENV=production

# 数据库配置
MONGODB_URI=mongodb://localhost:27017/barrelManagement

# 安全配置
CORS_ORIGINS=http://$(hostname -I | awk '{print $1}'),https://$(hostname -I | awk '{print $1}')

# 二维码配置
QR_CODE_SIZE=256
QR_CODE_ERROR_CORRECTION=L
QR_CODE_MARGIN=4

# 日志配置
LOG_LEVEL=info
LOG_FORMAT=json

# 服务器信息
SERVER_HOST=$(hostname -I | awk '{print $1}')
SERVER_PORT=3000
EOF

# 创建systemd服务文件
echo "🚀 创建系统服务..."
cat > /etc/systemd/system/barrel-management.service << EOF
[Unit]
Description=Barrel Management System
After=network.target mongod.service

[Service]
Type=simple
User=www-data
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node server.js
Restart=always
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=MONGODB_URI=mongodb://localhost:27017/barrelManagement
Environment=SERVER_HOST=$(hostname -I | awk '{print $1}')

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
echo "⚙️ 启动应用服务..."
systemctl daemon-reload
systemctl start barrel-management
systemctl enable barrel-management

# 配置Nginx反向代理
echo "🌐 配置Nginx..."
apt install -y nginx

cat > /etc/nginx/sites-available/barrel-management << EOF
server {
    listen 80;
    server_name _;

    # 静态文件缓存
    location /static {
        alias $APP_DIR/public;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API代理
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
    }

    # 前端路由
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # 错误页面
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

# 启用Nginx站点
ln -sf /etc/nginx/sites-available/barrel-management /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# 防火墙配置
echo "🛡️ 配置防火墙..."
ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable

# 创建部署完成提示文件
echo "🎉 部署完成！" > /var/www/barrel-management/DEPLOYMENT_COMPLETE.txt
echo "应用查看地址: http://$(hostname -I | awk '{print $1}')" >> /var/www/barrel-management/DEPLOYMENT_COMPLETE.txt
echo "服务状态: systemctl status barrel-management" >> /var/www/barrel-management/DEPLOYMENT_COMPLETE.txt
echo "日志查看: journalctl -u barrel-management -f" >> /var/www/barrel-management/DEPLOYMENT_COMPLETE.txt

echo "✅ 真正的一键部署已完成！"
echo "访问地址: http://$(hostname -I | awk '{print $1}')"
echo "服务状态: systemctl status barrel-management"
echo "日志查看: journalctl -u barrel-management -f"
echo "部署完成文件: /var/www/barrel-management/DEPLOYMENT_COMPLETE.txt"