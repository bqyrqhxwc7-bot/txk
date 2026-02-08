#!/bin/bash

# 前端文件检查脚本
# 检查静态文件是否正常

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 开始检查前端文件...${NC}"

APP_DIR="/var/www/barrel-management"
cd "$APP_DIR"

echo "📋 检查关键前端文件:"

# 检查必要文件
FILES=("index.html" "style.css" "script.js")
ALL_OK=true

for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        echo -e "${GREEN}✅ $FILE 存在${NC}"
        # 检查文件大小
        SIZE=$(wc -c < "$FILE")
        if [ "$SIZE" -eq 0 ]; then
            echo -e "${YELLOW}⚠️  $FILE 大小为0字节${NC}"
            ALL_OK=false
        fi
    else
        echo -e "${RED}❌ $FILE 不存在${NC}"
        ALL_OK=false
    fi
done

# 检查服务配置
echo ""
echo "📋 检查服务配置:"
if grep -q "express.static" server.js; then
    echo -e "${GREEN}✅ server.js 包含静态文件服务配置${NC}"
else
    echo -e "${RED}❌ server.js 缺少静态文件服务配置${NC}"
    ALL_OK=false
fi

# 测试本地访问
echo ""
echo "📋 测试本地访问:"
if command -v curl >/dev/null 2>&1; then
    echo "正在测试本地健康检查..."
    if curl -s http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 健康检查接口正常${NC}"
        
        # 测试首页
        echo "正在测试首页..."
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
        case $RESPONSE in
            200)
                echo -e "${GREEN}✅ 首页返回200状态码${NC}"
                ;;
            404)
                echo -e "${YELLOW}⚠️ 首页返回404，可能静态文件路径问题${NC}"
                ;;
            *)
                echo -e "${RED}❌ 首页返回状态码: $RESPONSE${NC}"
                ALL_OK=false
                ;;
        esac
    else
        echo -e "${YELLOW}⚠️ 健康检查接口无响应${NC}"
        ALL_OK=false
    fi
else
    echo "${YELLOW}⚠️ curl未安装，跳过测试${NC}"
fi

echo ""
if [ "$ALL_OK" = true ]; then
    echo -e "${GREEN}🎉 所有检查通过！${NC}"
    echo "如果仍有黑屏问题，请检查："
    echo "1. 浏览器控制台是否有404错误"
    echo "2. 网络请求中静态文件是否加载成功"
    echo "3. 尝试清除浏览器缓存"
else
    echo -e "${RED}❌ 发现问题，请根据上述检查结果修复${NC}"
fi

echo ""
echo "🔧 建议操作："
echo "1. 重新部署：sudo systemctl restart barrel-management"
echo "2. 检查浏览器开发者工具的Network标签"
echo "3. 查看具体404的文件路径"