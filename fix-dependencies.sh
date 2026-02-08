#!/bin/bash

# 依赖修复脚本
# 解决canvas等原生模块缺失问题

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 开始修复依赖问题...${NC}"

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}此脚本必须以root权限运行${NC}" 
   exit 1
fi

APP_DIR="/var/www/barrel-management"
cd "$APP_DIR"

echo "📋 当前工作目录: $(pwd)"

# 安装canvas所需的系统依赖
echo "🛠️ 安装canvas系统依赖..."
apt update
apt install -y \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev

# 停止服务
echo "⏹️ 停止应用服务..."
systemctl stop barrel-management 2>/dev/null || true

# 清理现有node_modules
echo "🧹 清理现有依赖..."
rm -rf node_modules package-lock.json

# 重新安装依赖
echo "📥 重新安装依赖..."
npm install --production

# 验证关键模块是否存在
echo "✅ 验证依赖安装..."
if node -e "require('canvas'); console.log('canvas模块加载成功')"; then
    echo -e "${GREEN}✅ canvas模块安装成功${NC}"
else
    echo -e "${RED}❌ canvas模块仍有问题${NC}"
    exit 1
fi

# 启动服务
echo "🚀 启动应用服务..."
systemctl start barrel-management

# 检查服务状态
sleep 3
if systemctl is-active --quiet barrel-management; then
    echo -e "${GREEN}✅ 服务启动成功${NC}"
    echo "应用查看: http://$(hostname -I | awk '{print $1}'):3000"
    echo "健康检查: http://$(hostname -I | awk '{print $1}'):3000/health"
else
    echo -e "${RED}❌ 服务启动失败${NC}"
    echo "查看详细日志: journalctl -u barrel-management -f"
    exit 1
fi

echo -e "${GREEN}🎉 依赖修复完成！${NC}"