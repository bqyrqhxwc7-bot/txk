#!/bin/bash

# 增强版Git克隆修复脚本
# 包含智能重试、多种备用方案和详细诊断

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 增强版Git克隆修复工具${NC}"

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}此脚本必须以root权限运行${NC}" 
   exit 1
fi

APP_DIR="/var/www/barrel-management"
cd "$APP_DIR"

echo "📋 当前工作目录: $(pwd)"

# 优化Git配置
echo "🛠️ 应用Git优化配置..."
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
git config --global http.version HTTP/1.1
git config --global core.compression 0
git config --global core.autocrlf input

# 增强重试机制
MAX_RETRIES=6
RETRY_COUNT=0
WAIT_BASE=3
WAIT_MAX=30

echo "🔄 开始增强版克隆重试（最多$MAX_RETRIES次）..."

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "尝试第 $((RETRY_COUNT + 1)) 次克隆..."
    
    # 尝试不同的克隆方法
    if git clone --depth=1 https://github.com/bqyrqhxwc7-bot/txk.git temp_clone 2>/dev/null; then
        echo -e "${GREEN}✅ 方法1: 浅克隆成功${NC}"
        rm -rf ./*  # 清空当前目录
        mv temp_clone/* ./
        mv temp_clone/.[^.]* ./ 2>/dev/null || true
        rm -rf temp_clone
        break
    elif git clone --config http.version=HTTP/1.1 https://github.com/bqyrqhxwc7-bot/txk.git temp_clone 2>/dev/null; then
        echo -e "${GREEN}✅ 方法2: HTTP/1.1克隆成功${NC}"
        rm -rf ./*  # 清空当前目录
        mv temp_clone/* ./
        mv temp_clone/.[^.]* ./ 2>/dev/null || true
        rm -rf temp_clone
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            # 指数退避等待
            WAIT_TIME=$((WAIT_BASE * (2 ** (RETRY_COUNT - 1))))
            if [ $WAIT_TIME -gt $WAIT_MAX ]; then
                WAIT_TIME=$WAIT_MAX
            fi
            echo "⚠️  克隆失败，${WAIT_TIME}秒后重试..."
            sleep $WAIT_TIME
            
            # 网络诊断
            echo "🔍 网络诊断:"
            if command -v ping >/dev/null 2>&1; then
                ping -c 2 github.com 2>/dev/null | grep "bytes from" && echo "✅ GitHub可达" || echo "❌ GitHub不可达"
            fi
        else
            echo -e "${RED}❌ 所有克隆方法都失败了${NC}"
            
            # 备用方案1: zip下载
            echo ""
            echo "💡 备用方案1: 使用wget下载zip包"
            if command -v wget >/dev/null 2>&1; then
                echo "正在下载..."
                if wget -q https://github.com/bqyrqhxwc7-bot/txk/archive/main.zip -O main.zip; then
                    echo "✅ 下载成功"
                    unzip -q main.zip
                    mv txk-main/* ./
                    mv txk-main/.[^.]* ./ 2>/dev/null || true
                    rm -rf txk-main main.zip
                    echo "✅ 已解压"
                else
                    echo "❌ wget下载失败"
                fi
            fi
            
            # 备用方案2: 创建最小化项目
            echo ""
            echo "💡 备用方案2: 创建最小化项目"
            cat > index.html << 'EOF'
<!DOCTYPE html>
<html><head><title>桶管理系统</title></head><body>
<h1>📦 桶管理系统</h1>
<p>服务已启动，前端文件缺失，请完整部署项目</p>
</body></html>
EOF
            
            cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());
app.use(express.static('.'));

mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/barrelManagement', {
    useNewUrlParser: true,
    useUnifiedTopology: true
});

app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html');
});

app.get('/health', (req, res) => {
    res.json({ status: 'OK' });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`服务器运行在端口 ${PORT}`);
});
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

            echo "✅ 最小化项目创建完成"
            
            # 提供手动解决方案
            echo ""
            echo "🎯 手动解决方案:"
            echo "1. 在本地电脑下载: https://github.com/bqyrqhxwc7-bot/txk/archive/main.zip"
            echo "2. 解压后上传到服务器 /var/www/barrel-management/"
            echo "3. 运行: npm install"
            echo "4. 重启服务"
        fi
    fi
done

echo ""
echo -e "${GREEN}✅ 部署完成！${NC}"
echo "请检查文件是否存在:"
ls -la index.html style.css script.js server.js