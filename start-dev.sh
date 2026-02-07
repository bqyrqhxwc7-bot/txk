#!/bin/bash

# 本地开发环境启动脚本

echo "🚀 启动桶管理系统开发环境..."

# 检查Node.js是否安装
if ! command -v node &> /dev/null; then
    echo "❌ 未找到Node.js，请先安装Node.js"
    exit 1
fi

# 检查MongoDB是否运行
if ! pgrep -x "mongod" > /dev/null; then
    echo "⚠️  MongoDB未运行，正在启动..."
    sudo systemctl start mongod || echo "请手动启动MongoDB: sudo systemctl start mongod"
fi

# 安装依赖
echo "📦 安装依赖..."
npm install

# 启动开发服务器
echo "🔧 启动开发服务器..."
echo "应用查看地址: http://localhost:3000"
echo "按 Ctrl+C 停止服务"

npm run dev