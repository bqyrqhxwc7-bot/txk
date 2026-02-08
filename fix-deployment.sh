#!/bin/bash

# 部署问题修复脚本
# 用于解决/var/www/barrel-management目录相关的部署问题

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 开始修复部署问题...${NC}"

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}此脚本必须以root权限运行${NC}" 
   exit 1
fi

APP_DIR="/var/www/barrel-management"

echo "📋 当前状态检查:"
echo "  - 应用目录: $APP_DIR"
echo "  - 目录存在: $(if [ -d "$APP_DIR" ]; then echo "是"; else echo "否"; fi)"

# 如果目录存在但有问题，进行清理
if [ -d "$APP_DIR" ]; then
    echo -e "${YELLOW}⚠️  发现现有目录，正在进行清理...${NC}"
    
    # 备份重要配置文件
    if [ -f "$APP_DIR/.env" ]; then
        cp "$APP_DIR/.env" "/tmp/env_backup_$(date +%s)" 2>/dev/null || true
        echo "💾 已备份 .env 文件"
    fi
    
    # 强制删除目录
    rm -rf "$APP_DIR"
    echo "🗑️  已强制删除问题目录"
fi

# 重新创建目录
mkdir -p "$APP_DIR"
chmod 755 "$APP_DIR"
echo -e "${GREEN}✅ 目录已成功创建: $APP_DIR${NC}"

# 检查目录权限
if [ -w "$APP_DIR" ]; then
    echo -e "${GREEN}✅ 目录写入权限正常${NC}"
else
    echo -e "${RED}❌ 目录写入权限异常${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 修复完成！现在可以重新运行部署脚本${NC}"
echo ""
echo "💡 建议执行:"
echo "   cd $APP_DIR"
echo "   curl -O https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/deploy.sh"
echo "   chmod +x deploy.sh"
echo "   ./deploy.sh"