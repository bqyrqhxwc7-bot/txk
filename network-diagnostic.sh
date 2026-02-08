#!/bin/bash

# 网络诊断脚本
# 诊断ERR_CONNECTION_TIMED_OUT问题

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 网络诊断开始...${NC}"

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   echo -e "${YELLOW}⚠️  建议以root权限运行以获得完整诊断信息${NC}"
fi

echo ""
echo "📋 1. 系统基本信息"
echo "主机名: $(hostname)"
echo "内核版本: $(uname -r)"
echo "Node.js版本: $(node --version 2>/dev/null || echo '未安装')"

echo ""
echo "📋 2. 网络接口信息"
ip addr show

echo ""
echo "📋 3. 端口监听检查"
echo "3000端口监听情况:"
sudo netstat -tlnp | grep :3000
sudo ss -tlnp | grep :3000

echo ""
echo "📋 4. 防火墙状态"
echo "UFW防火墙:"
sudo ufw status 2>/dev/null || echo "UFW未安装或不可用"

echo "iptables规则:"
sudo iptables -L -n | grep 3000 2>/dev/null || echo "iptables未找到相关规则"

echo ""
echo "📋 5. 服务状态"
systemctl status barrel-management 2>/dev/null || echo "服务状态无法获取"

echo ""
echo "📋 6. 本地测试"
echo "测试本地连接:"
if command -v curl >/dev/null 2>&1; then
    echo "curl测试:"
    curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" http://localhost:3000/health 2>/dev/null || echo "连接失败"
    
    echo "telnet测试:"
    if command -v telnet >/dev/null 2>&1; then
        timeout 5 telnet localhost 3000 2>&1 | head -n 1
    else
        echo "telnet未安装，使用nc测试:"
        if command -v nc >/dev/null 2>&1; then
            timeout 5 nc -zv localhost 3000 2>&1 | head -n 1
        else
            echo "nc未安装"
        fi
    fi
else
    echo "curl未安装"
fi

echo ""
echo "📋 7. 外部访问诊断"
echo "请在浏览器中访问以下地址进行测试："
echo "- http://$(hostname -I | awk '{print $1}'):3000/health"
echo "- http://127.0.0.1:3000/health"
echo "- http://localhost:3000/health"

echo ""
echo "🔍 诊断结果分析："
echo "✅ 如果本地测试成功但外部访问失败 → 防火墙/安全组问题"
echo "❌ 如果本地测试也失败 → 服务未正确启动或绑定问题"
echo "⚠️ 如果显示'Connection refused' → 服务未监听该端口"
echo "⏳ 如果显示'timed out' → 网络连接被阻止或服务无响应"

echo ""
echo "🔧 建议操作："
echo "1. 如果服务未监听3000端口：重启服务并检查server.js绑定配置"
echo "2. 如果防火墙阻止：sudo ufw allow 3000 && sudo ufw reload"
echo "3. 如果是云服务器：检查安全组规则是否开放3000端口"
echo "4. 如果IP地址不匹配：使用正确的服务器IP地址"