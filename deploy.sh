#!/bin/bash

# 桶管理系统一键部署脚本
# 支持Ubuntu 20.04+/Debian 11+
# 作者: Your Name
# 版本: 1.0

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 错误处理函数
error_exit() {
    echo -e "${RED}❌ 错误: $1${NC}" >&2
    exit 1
}

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}此脚本必须以root权限运行${NC}" 
   exit 1
fi

echo -e "${BLUE}🚀 开始部署桶管理系统...${NC}"

# 更新系统包
echo "🔄 更新系统包..."
apt update && apt upgrade -y

# 安装必要工具
echo "🔧 安装必要工具..."
apt install -y curl wget git gnupg lsb-release ufw

# 安装Node.js 18 LTS
echo "📦 安装Node.js 18 LTS..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# 验证Node.js安装
node_version=$(node --version)
npm_version=$(npm --version)
echo -e "${GREEN}✅ Node.js $node_version 和 npm $npm_version 安装完成${NC}"

# 安装MongoDB 6.0
echo "💾 安装MongoDB 6.0..."
# 创建密钥环目录
mkdir -p /etc/apt/keyrings

# 下载并安装GPG密钥
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

# 创建应用目录并处理目录存在性问题
echo "📁 创建应用目录..."
APP_DIR="/var/www/barrel-management"

# 简单直接的处理方式
if [ -d "$APP_DIR" ]; then
    echo "⚠️  目录 '$APP_DIR' 已存在"
    # 备份重要文件
    if [ -f "$APP_DIR/.env" ]; then
        cp "$APP_DIR/.env" "/tmp/env_backup" 2>/dev/null || true
        echo "💾 已备份 .env 文件"
    fi
    
    # 删除整个目录并重新创建
    rm -rf "$APP_DIR"
    echo "🗑️  已删除旧目录"
fi

# 创建新目录
mkdir -p "$APP_DIR"
echo "✅ 目录创建完成"

# 恢复备份的配置文件
if [ -f "/tmp/env_backup" ]; then
    cp "/tmp/env_backup" "$APP_DIR/.env" 2>/dev/null || true
    rm -f "/tmp/env_backup"
    echo "🔄 已恢复 .env 配置文件"
fi

cd "$APP_DIR"

# 自动克隆GitHub仓库（使用标准URL格式）
echo "📥 自动克隆GitHub项目..."

# 设置Git配置以提高克隆成功率
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
git config --global core.compression 0

# 尝试多次克隆，增加重试机制
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "🔄 尝试第 $((RETRY_COUNT + 1)) 次克隆..."
    
    if git clone https://github.com/bqyrqhxwc7-bot/txk.git . 2>/dev/null; then
        echo "✅ 项目代码克隆成功"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "⚠️  克隆失败，${RETRY_COUNT}秒后重试..."
            sleep $RETRY_COUNT
        else
            echo "❌ 多次尝试克隆失败"
            
            # 提供手动下载选项
            echo "💡 尝试备用方案：手动下载项目文件"
            
            # 创建基本项目结构
            mkdir -p public
            cat > server.js << 'EOF'
const express = require('express');
const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(express.json());
app.use(express.static('public'));

// MongoDB连接
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/barrelManagement', {
    useNewUrlParser: true,
    useUnifiedTopology: true
});

// 基础路由
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
EOF

            cat > package.json << 'EOF'
{
  "name": "barrel-management",
  "version": "1.0.0",
  "description": "现代化桶管理系统",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.17.3",
    "mongoose": "^6.12.4",
    "dotenv": "^16.0.3"
  },
  "devDependencies": {
    "nodemon": "^2.0.20"
  },
  "engines": {
    "node": ">=14.17.0"
  }
}
EOF

            echo "✅ 已创建基础项目文件，您可以手动添加前端文件"
            break
        fi
    fi
done

# 安装sharp库所需的系统依赖（修正包名问题）
echo "🛠️ 安装sharp库系统依赖..."
# 先更新软件源
apt update

# 安装核心依赖（已验证在Ubuntu 20.04+上可用）
apt install -y \
    libvips-dev \
    libglib2.0-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libgif-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libwebp-dev \
    libxml2-dev

# 如果上述包仍不可用，尝试安装通用开发包
if ! dpkg -l | grep -q libglib2.0-dev; then
    echo "⚠️  尝试安装替代依赖..."
    apt install -y build-essential libtool autoconf automake
fi

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

echo "✅ 部署已完成！"
echo "访问地址: http://$(hostname -I | awk '{print $1}')"
echo "服务状态: systemctl status barrel-management"
echo "日志查看: journalctl -u barrel-management -f"
echo "部署完成文件: /var/www/barrel-management/DEPLOYMENT_COMPLETE.txt"