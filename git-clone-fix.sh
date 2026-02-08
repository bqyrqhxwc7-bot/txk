#!/bin/bash

# Git克隆问题修复脚本
# 解决HTTP2 framing layer错误和其他Git克隆问题

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Git克隆问题修复工具${NC}"

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}此脚本必须以root权限运行${NC}" 
   exit 1
fi

APP_DIR="/var/www/barrel-management"
cd "$APP_DIR"

echo "📋 当前Git配置检查:"
git config --global --list | grep -E "(http|ssl)" || echo "无特殊配置"

echo ""
echo "🔧 应用Git优化配置..."

# 优化Git配置
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
git config --global http.version HTTP/1.1
git config --global core.compression 0
git config --global ssh.version SSH-2.0

echo "✅ Git配置已优化"

echo ""
echo "🔄 尝试不同的克隆方法..."

# 方法1: 使用HTTP/1.1
echo "尝试方法1: 强制使用HTTP/1.1..."
if git clone --config http.version=HTTP/1.1 https://github.com/bqyrqhxwc7-bot/txk.git temp_clone 2>/dev/null; then
    echo -e "${GREEN}✅ 方法1成功${NC}"
    rm -rf ./*  # 清空当前目录
    mv temp_clone/* ./
    mv temp_clone/.[^.]* ./ 2>/dev/null || true
    rm -rf temp_clone
    exit 0
fi

# 方法2: 禁用压缩
echo "尝试方法2: 禁用压缩..."
if git clone --config core.compression=0 https://github.com/bqyrqhxwc7-bot/txk.git temp_clone 2>/dev/null; then
    echo -e "${GREEN}✅ 方法2成功${NC}"
    rm -rf ./*  # 清空当前目录
    mv temp_clone/* ./
    mv temp_clone/.[^.]* ./ 2>/dev/null || true
    rm -rf temp_clone
    exit 0
fi

# 方法3: 使用深度克隆
echo "尝试方法3: 浅克隆..."
if git clone --depth 1 https://github.com/bqyrqhxwc7-bot/txk.git temp_clone 2>/dev/null; then
    echo -e "${GREEN}✅ 方法3成功${NC}"
    rm -rf ./*  # 清空当前目录
    mv temp_clone/* ./
    mv temp_clone/.[^.]* ./ 2>/dev/null || true
    rm -rf temp_clone
    exit 0
fi

# 方法4: 分步克隆
echo "尝试方法4: 分步克隆..."
git init
git remote add origin https://github.com/bqyrqhxwc7-bot/txk.git
if git fetch --depth 1 origin main 2>/dev/null && git checkout FETCH_HEAD 2>/dev/null; then
    echo -e "${GREEN}✅ 方法4成功${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}⚠️  所有Git克隆方法都失败了${NC}"
echo "💡 提供手动解决方案:"

echo ""
echo "选项1: 使用wget下载zip包"
echo "cd $APP_DIR"
echo "wget https://github.com/bqyrqhxwc7-bot/txk/archive/main.zip"
echo "unzip main.zip"
echo "mv txk-main/* ./"
echo "mv txk-main/.[^.]* ./ 2>/dev/null || true"
echo "rm -rf txk-main main.zip"

echo ""
echo "选项2: 使用curl下载"
echo "cd $APP_DIR"
echo "curl -L https://github.com/bqyrqhxwc7-bot/txk/archive/main.tar.gz -o main.tar.gz"
echo "tar -xzf main.tar.gz"
echo "mv txk-main/* ./"
echo "mv txk-main/.[^.]* ./ 2>/dev/null || true"
echo "rm -rf txk-main main.tar.gz"

echo ""
echo "选项3: 检查网络连接"
echo "ping github.com"
echo "traceroute github.com"

echo ""
echo -e "${GREEN}✅ 修复脚本执行完成${NC}"
echo "请根据上述建议选择合适的解决方案"