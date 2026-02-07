#!/bin/bash

# 桶管理系统一键部署脚本
# 适用于Ubuntu 20.04 LTS及以上版本

set -e

echo "🚀 开始部署桶管理系统..."

# 检查root权限
if [ "$EUID" -ne 0 ]; then
  echo "请以root用户运行此脚本"
  exit 1
fi

# 更新系统
echo "🔄 更新系统..."
apt update && apt upgrade -y

# 安装必要软件
echo "📦 安装Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs

# 安装MongoDB（修复apt-key弃用问题）
echo "📦 安装MongoDB..."
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

# 启动MongoDB
echo "🔧 启动MongoDB..."
systemctl start mongod
systemctl enable mongod

# 创建应用目录
echo "📁 创建应用目录..."
APP_DIR="/var/www/barrel-management"
mkdir -p $APP_DIR
cd $APP_DIR

# 这里需要手动上传应用代码
echo "📋 请手动上传应用代码到 $APP_DIR"
echo "可以使用以下命令："
echo "scp -r ./ root@your-server-ip:$APP_DIR/"

# 等待用户确认代码已上传
read -p "确认代码已上传完成？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "请先上传代码再继续"
    exit 1
fi

# 安装应用依赖
echo "📥 安装应用依赖..."
npm install --production

# 创建systemd服务文件
echo "⚙️ 创建系统服务..."
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

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
echo "🚀 启动应用服务..."
systemctl daemon-reload
systemctl start barrel-management
systemctl enable barrel-management

# 配置Nginx
echo "🌐 配置Nginx..."
apt install -y nginx

cat > /etc/nginx/sites-available/barrel-management << EOF
server {
    listen 80;
    server_name _;

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
}
EOF

ln -sf /etc/nginx/sites-available/barrel-management /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# 防火墙配置
echo "🛡️ 配置防火墙..."
ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable

echo "✅ 部署完成！"
echo "应用查看地址: http://$(hostname -I | awk '{print $1}')"
echo "服务状态: systemctl status barrel-management"
echo "日志查看: journalctl -u barrel-management -f"