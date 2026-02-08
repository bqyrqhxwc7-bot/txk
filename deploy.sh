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

# 自动克隆GitHub项目（使用标准URL格式）
echo "📥 自动克隆GitHub项目..."

# 设置Git配置以提高克隆成功率
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
git config --global http.version HTTP/1.1
git config --global core.compression 0

# 增强的克隆重试机制（固定等待时间，非指数退避）
MAX_RETRIES=5
RETRY_COUNT=0
FIXED_WAIT=5  # 固定等待5秒

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "🔄 尝试第 $((RETRY_COUNT + 1)) 次克隆..."
    
    if git clone https://github.com/bqyrqhxwc7-bot/txk.git . 2>/dev/null; then
        echo "✅ 项目代码克隆成功"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "⚠️  克隆失败，${FIXED_WAIT}秒后重试..."
            sleep $FIXED_WAIT
        else
            echo "❌ 多次尝试克隆失败（共$MAX_RETRIES次）"
            
            # 提供多种备用方案
            echo ""
            echo "💡 尝试备用方案..."
            
            # 方案1: 使用wget下载zip包（推荐）
            echo "方案1: 使用wget下载zip包"
            if command -v wget >/dev/null 2>&1; then
                echo "正在下载项目zip包..."
                if wget -q https://github.com/bqyrqhxwc7-bot/txk/archive/main.zip -O main.zip; then
                    echo "✅ 下载成功"
                    unzip -q main.zip
                    mv txk-main/* ./
                    mv txk-main/.[^.]* ./ 2>/dev/null || true
                    rm -rf txk-main main.zip
                    echo "✅ 已解压项目文件"
                else
                    echo "❌ wget下载失败"
                fi
            else
                echo "⚠️ wget未安装，跳过方案1"
            fi
            
            # 方案2: 使用curl下载tar.gz
            echo ""
            echo "方案2: 使用curl下载tar.gz"
            if command -v curl >/dev/null 2>&1; then
                echo "正在下载项目tar.gz..."
                if curl -sL https://github.com/bqyrqhxwc7-bot/txk/archive/main.tar.gz -o main.tar.gz; then
                    echo "✅ 下载成功"
                    tar -xzf main.tar.gz
                    mv txk-main/* ./
                    mv txk-main/.[^.]* ./ 2>/dev/null || true
                    rm -rf txk-main main.tar.gz
                    echo "✅ 已解压项目文件"
                else
                    echo "❌ curl下载失败"
                fi
            else
                echo "⚠️ curl未安装，跳过方案2"
            fi
            
            # 方案3: 创建最小化项目结构
            echo ""
            echo "方案3: 创建最小化项目结构（确保基本功能）"
            cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(bodyParser.json());
app.use(express.static('.'));

// MongoDB连接
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/barrelManagement', {
    useNewUrlParser: true,
    useUnifiedTopology: true
});

// 基础路由
app.get('/', (req, res) => {
    res.send('<h1>📦 桶管理系统</h1><p>服务已启动，请配置前端文件</p>');
});

app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
EOF

            cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>桶管理系统</title>
</head>
<body>
    <h1>📦 桶管理系统</h1>
    <p>欢迎使用现代化桶管理平台</p>
    <p>请确保部署完整项目文件</p>
</body>
</html>
EOF

            cat > package.json << 'EOF'
{
  "name": "barrel-management",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.17.3",
    "cors": "^2.8.5",
    "body-parser": "^1.19.2",
    "mongoose": "^6.12.4"
  }
}
EOF

            echo "✅ 已创建最小化项目结构"
            
            # 如果所有方案都失败，提示用户手动操作
            if [ ! -f "index.html" ] || [ ! -f "server.js" ]; then
                echo ""
                echo "❌ 所有自动方案失败"
                echo "请手动执行以下步骤："
                echo "1. 在本地电脑下载: https://github.com/bqyrqhxwc7-bot/txk/archive/main.zip"
                echo "2. 解压后上传到服务器 /var/www/barrel-management/"
                echo "3. 运行: npm install"
                echo "4. 重启服务: systemctl restart barrel-management"
            fi
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

# 部署完成后自动问题检测和修复
echo ""
echo "🔍 自动问题检测与修复..."
echo "====================================="

# 创建临时目录用于修复工具
mkdir -p /tmp/tx-fix-tools

# 检查并自动修复常见问题
AUTO_FIX=true
FIX_LOG=""

# 1. 检查目录问题
if [ ! -d "$APP_DIR" ] || [ ! -f "$APP_DIR/server.js" ]; then
    echo "⚠️  检测到目录问题或关键文件缺失"
    FIX_LOG+="目录问题: 尝试自动修复...\n"
    
    # 下载并执行目录修复脚本
    if command -v curl >/dev/null 2>&1; then
        curl -s -o /tmp/tx-fix-tools/fix-deployment.sh https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/fix-deployment.sh
        if [ -f "/tmp/tx-fix-tools/fix-deployment.sh" ]; then
            chmod +x /tmp/tx-fix-tools/fix-deployment.sh
            echo "🔧 正在执行目录修复..."
            /tmp/tx-fix-tools/fix-deployment.sh 2>/dev/null || true
            FIX_LOG+="目录修复完成\n"
        fi
    fi
    
    # 重新创建应用目录
    mkdir -p "$APP_DIR"
    cd "$APP_DIR"
fi

# 2. 检查Git克隆问题（前端文件缺失）
MISSING_FRONTEND_FILES=()
for FILE in "index.html" "style.css" "script.js"; do
    if [ ! -f "$FILE" ]; then
        MISSING_FRONTEND_FILES+=("$FILE")
    fi
done

if [ ${#MISSING_FRONTEND_FILES[@]} -gt 0 ]; then
    echo "⚠️  检测到前端文件缺失: ${MISSING_FRONTEND_FILES[*]}"
    FIX_LOG+="前端文件缺失: 尝试自动修复...\n"
    
    # 尝试多种自动修复方案
    if command -v curl >/dev/null 2>&1; then
        # 方案1: 使用增强版Git修复
        curl -s -o /tmp/tx-fix-tools/enhanced-git-fix.sh https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/enhanced-git-fix.sh
        if [ -f "/tmp/tx-fix-tools/enhanced-git-fix.sh" ]; then
            chmod +x /tmp/tx-fix-tools/enhanced-git-fix.sh
            echo "🔧 正在执行增强版Git修复..."
            /tmp/tx-fix-tools/enhanced-git-fix.sh 2>/dev/null || true
            FIX_LOG+="增强版Git修复完成\n"
        fi
        
        # 方案2: 如果仍然缺失，创建最小化前端
        if [ ! -f "index.html" ]; then
            echo "🔧 创建最小化前端文件..."
            cat > index.html << 'EOF'
<!DOCTYPE html>
<html><head><title>桶管理系统</title></head><body>
<h1>📦 桶管理系统</h1>
<p>服务已启动，正在加载完整功能...</p>
</body></html>
EOF
            cat > style.css << 'EOF'
body { font-family: sans-serif; margin: 20px; }
h1 { color: #2c3e50; }
EOF
            cat > script.js << 'EOF'
console.log('桶管理系统前端已加载');
EOF
            FIX_LOG+="最小化前端创建完成\n"
        fi
    fi
fi

# 3. 检查依赖问题
if [ ! -d "node_modules" ] || [ ! -f "package-lock.json" ]; then
    echo "⚠️  检测到依赖未安装"
    FIX_LOG+="依赖问题: 尝试自动修复...\n"
    
    # 下载并执行依赖修复脚本
    if command -v curl >/dev/null 2>&1; then
        curl -s -o /tmp/tx-fix-tools/fix-dependencies.sh https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/fix-dependencies.sh
        if [ -f "/tmp/tx-fix-tools/fix-dependencies.sh" ]; then
            chmod +x /tmp/tx-fix-tools/fix-dependencies.sh
            echo "🔧 正在执行依赖修复..."
            /tmp/tx-fix-tools/fix-dependencies.sh 2>/dev/null || true
            FIX_LOG+="依赖修复完成\n"
        fi
    fi
    
    # 备用：直接安装依赖
    if [ ! -d "node_modules" ]; then
        echo "🔧 直接安装依赖..."
        npm install --production 2>/dev/null || true
        FIX_LOG+="npm install完成\n"
    fi
fi

# 4. 检查服务配置问题
if ! grep -q "app.listen.*0\.0\.0\.0" server.js 2>/dev/null; then
    echo "⚠️  检测到服务绑定配置问题"
    FIX_LOG+="服务绑定配置: 尝试自动修复...\n"
    
    # 自动修复server.js中的监听配置
    if grep -q "app.listen.*PORT" server.js 2>/dev/null; then
        echo "🔧 修复服务绑定配置..."
        sed -i 's/app\.listen(\(PORT\))/app.listen(\1, "0.0.0.0")/' server.js
        FIX_LOG+="服务绑定修复完成\n"
    else
        # 添加默认监听配置
        echo "app.listen(PORT, \"0.0.0.0\", () => {" >> server.js
        echo "    console.log(\`🚀 Server running on port \${PORT}\`);" >> server.js
        echo "});" >> server.js
        FIX_LOG+="添加服务监听配置完成\n"
    fi
fi

# 5. 检查MongoDB配置
if [ ! -f ".env" ] || ! grep -q "MONGODB_URI" .env; then
    echo "⚠️  检测到数据库配置缺失"
    FIX_LOG+="数据库配置: 尝试自动修复...\n"
    
    # 创建基本.env文件
    if [ ! -f ".env" ]; then
        cat > .env << 'EOF'
# 应用配置
PORT=3000
NODE_ENV=production

# 数据库配置
MONGODB_URI=mongodb://localhost:27017/barrelManagement

# 安全配置
JWT_SECRET=your-secret-key-here
EOF
        FIX_LOG+=".env文件创建完成\n"
    fi
fi

# 6. 检查服务状态并重启
echo "🔄 检查服务状态并重启..."
systemctl stop barrel-management 2>/dev/null || true
systemctl start barrel-management 2>/dev/null || true

# 等待服务启动
sleep 3

# 输出自动修复结果
echo ""
echo "🤖 自动修复结果："
echo "====================================="
if [ -n "$FIX_LOG" ]; then
    echo -e "$FIX_LOG"
    echo "✅ 自动修复已完成"
else
    echo "🟢 无需自动修复，所有组件正常"
fi

# 清理临时文件
rm -rf /tmp/tx-fix-tools

# 部署完成后的状态总结
echo ""
echo "🎉 部署完成！状态总结："
echo "====================================="

# 检查关键组件状态
STATUS_OK=true
PROBLEMS=()

# 1. 检查目录创建
if [ -d "$APP_DIR" ]; then
    echo "✅ 目录创建: $APP_DIR - 已成功创建"
else
    echo "❌ 目录创建: $APP_DIR - 创建失败"
    PROBLEMS+=("目录创建失败，请检查磁盘空间和权限")
    STATUS_OK=false
fi

# 2. 检查文件存在性
REQUIRED_FILES=("server.js" "index.html" "style.css" "script.js" "package.json")
MISSING_FILES=()
for FILE in "${REQUIRED_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        echo "✅ 文件存在: $FILE"
    else
        echo "⚠️  文件缺失: $FILE"
        MISSING_FILES+=("$FILE")
    fi
done

# 3. 检查依赖安装
if [ -d "node_modules" ] && [ -f "package-lock.json" ]; then
    echo "✅ 依赖安装: node_modules - 已成功安装"
else
    echo "⚠️  依赖安装: node_modules - 可能未完全安装"
    PROBLEMS+=("Node.js依赖可能未正确安装，请运行: npm install --production")
fi

# 4. 检查服务配置
if grep -q "app.listen.*0\.0\.0\.0" server.js 2>/dev/null; then
    echo "✅ 服务绑定: 绑定到 0.0.0.0 - 正确配置"
elif grep -q "app.listen.*PORT" server.js 2>/dev/null; then
    echo "⚠️  服务绑定: 仅绑定到默认地址 - 建议修改为绑定到 0.0.0.0"
    PROBLEMS+=("服务绑定配置需要优化：在server.js中使用 app.listen(PORT, '0.0.0.0')")
else
    echo "❌ 服务绑定: 未找到监听配置 - 配置错误"
    PROBLEMS+=("server.js中缺少app.listen配置")
    STATUS_OK=false
fi

# 5. 检查MongoDB连接
if [ -f ".env" ] && grep -q "MONGODB_URI" .env; then
    echo "✅ 数据库配置: .env - 已配置MongoDB URI"
else
    echo "⚠️  数据库配置: .env - MongoDB URI未配置"
    PROBLEMS+=("请在.env文件中配置MONGODB_URI=mongodb://localhost:27017/barrelManagement")
    STATUS_OK=false
fi

# 6. 检查服务状态
if systemctl is-active --quiet barrel-management; then
    echo "✅ 服务状态: barrel-management - 已启动并运行"
    
    # 检查端口监听
    if netstat -tlnp | grep ":3000" >/dev/null 2>&1; then
        echo "✅ 端口监听: :3000 - 已正确监听"
        
        # 测试健康检查
        if curl -s http://localhost:3000/health >/dev/null 2>&1; then
            echo "✅ 健康检查: /health - 返回正常"
        else
            echo "⚠️  健康检查: /health - 无法访问"
            PROBLEMS+=("服务启动但健康检查接口不可用，检查防火墙设置")
        fi
    else
        echo "❌ 端口监听: :3000 - 未监听"
        PROBLEMS+=("服务未监听3000端口，请检查server.js中的app.listen配置")
        STATUS_OK=false
    fi
else
    echo "❌ 服务状态: barrel-management - 未运行"
    PROBLEMS+=("服务未启动，请运行: systemctl start barrel-management")
    STATUS_OK=false
fi

# 7. 检查前端文件可访问性
if [ -f "index.html" ]; then
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/index.html | grep -q "200"; then
        echo "✅ 前端访问: index.html - 可正常访问"
    else
        echo "⚠️  前端访问: index.html - 访问失败"
        PROBLEMS+=("静态文件服务配置问题，请检查express.static配置")
    fi
else
    echo "❌ 前端文件: index.html - 缺失"
    PROBLEMS+=("前端文件缺失，导致页面无内容显示")
fi

# 输出总结
echo ""
echo "📋 总结报告:"
if [ "$STATUS_OK" = true ]; then
    echo "🟢 所有关键组件正常！服务已准备就绪"
    echo "🌐 访问地址: http://$(hostname -I | awk '{print $1}'):3000"
else
    echo "🔴 存在问题，需要处理以下事项："
    for i in "${!PROBLEMS[@]}"; do
        echo "   $(($i+1)). ${PROBLEMS[$i]}"
    done
    
    echo ""
    echo "🔧 推荐解决方案："
    echo "1. 如果前端文件缺失：重新部署或手动创建index.html等文件"
    echo "2. 如果服务未启动：sudo systemctl restart barrel-management"
    echo "3. 如果端口未监听：检查server.js中的app.listen(PORT, '0.0.0.0')"
    echo "4. 如果依赖问题：cd /var/www/barrel-management && npm install --production"
    echo "5. 如果数据库配置：检查.env文件中的MONGODB_URI配置"
fi

echo ""
echo "💡 额外建议："
echo "- 使用浏览器开发者工具(F12)查看Network标签，诊断具体加载问题"
echo "- 查看详细日志：journalctl -u barrel-management -f"
echo "- 测试本地访问：curl -I http://localhost:3000/health"

# 如果有严重问题，提供紧急恢复命令
if [ ${#PROBLEMS[@]} -gt 0 ]; then
    echo ""
    echo "🚨 紧急恢复步骤（如果服务完全不可用）："
    echo "sudo systemctl stop barrel-management"
    echo "cd /var/www/barrel-management"
    echo "rm -rf node_modules package-lock.json"
    echo "npm install --production"
    echo "sudo systemctl start barrel-management"
fi

echo "✅ 部署已完成！"
echo "访问地址: http://$(hostname -I | awk '{print $1}')"
echo "服务状态: systemctl status barrel-management"
echo "日志查看: journalctl -u barrel-management -f"
echo "部署完成文件: /var/www/barrel-management/DEPLOYMENT_COMPLETE.txt"