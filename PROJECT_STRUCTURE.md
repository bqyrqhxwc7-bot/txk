# 📁 项目结构说明

```
barrel-management/
├── server.js              # 主服务器文件
├── index.html             # 前端主页面
├── style.css              # 样式文件
├── script.js              # 前端JavaScript
├── package.json           # Node.js依赖配置
├── deploy.sh              # 一键部署脚本
├── fix-deployment.sh      # 部署问题修复脚本
├── start-dev.sh           # 开发环境启动脚本
├── nginx.conf             # Nginx配置文件
├── docker-compose.yml     # Docker编排文件
├── Dockerfile             # Docker镜像构建文件
├── deploy-config.js       # 部署配置文件
├── .env.example          # 环境变量模板
├── README.md             # 项目说明文档
├── DEPLOYMENT.md         # 部署详细说明
├── DEPLOYMENT_TROUBLESHOOTING.md  # 部署故障排除指南
└── PROJECT_STRUCTURE.md   # 项目结构说明
```

## 📄 文件说明

### 核心应用文件
- **server.js**: Express服务器主文件，包含所有API路由和数据库连接逻辑
- **index.html**: 响应式前端界面，支持移动端和桌面端访问
- **style.css**: 现代化CSS样式，包含响应式设计和动画效果
- **script.js**: 前端交互逻辑，包含二维码扫描和状态管理功能

### 配置文件
- **package.json**: Node.js项目依赖和脚本配置
- **.env.example**: 环境变量配置模板
- **nginx.conf**: 生产环境Nginx反向代理配置
- **docker-compose.yml**: Docker容器编排配置
- **Dockerfile**: Docker镜像构建配置

### 部署相关
- **deploy.sh**: 🔧 一键部署脚本，自动化完成整个部署流程
- **fix-deployment.sh**: 🛠️ 部署问题修复脚本，解决目录和权限问题
- **start-dev.sh**: 🚀 开发环境快速启动脚本
- **deploy-config.js**: ⚙️ 部署配置参数文件

### 文档文件
- **README.md**: 📖 项目主文档，包含快速开始和基本使用说明
- **DEPLOYMENT.md**: 📋 详细的部署指南和技术说明
- **DEPLOYMENT_TROUBLESHOOTING.md**: 🔧 部署问题诊断和解决方案
- **PROJECT_STRUCTURE.md**: 📁 当前文件（项目结构说明）

## 🎯 关键特性

### 🔄 自动化部署
- 一键完成系统更新、依赖安装、服务配置
- 自动处理目录清理和权限设置
- 智能错误检测和恢复机制

### 🛡️ 安全防护
- 环境变量隔离敏感配置
- UFW防火墙自动配置
- systemd服务管理确保稳定性

### 📱 响应式设计
- 移动端优化的用户界面
- 触摸友好的交互体验
- 适应不同屏幕尺寸

### 🔍 功能完整
- 二维码生成和扫描
- 实时状态更新
- 数据持久化存储
- 健康检查监控

## 🚀 快速开始

```bash
# 一键部署（生产环境）
curl -O https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/deploy.sh
chmod +x deploy.sh
sudo ./deploy.sh

# 开发环境启动
./start-dev.sh

# 遇到问题时使用修复脚本
curl -O https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/fix-deployment.sh
chmod +x fix-deployment.sh
sudo ./fix-deployment.sh
```

## 📊 技术栈

- **后端**: Node.js + Express + MongoDB
- **前端**: HTML5 + CSS3 + JavaScript (ES6+)
- **部署**: Docker + Nginx + systemd
- **数据库**: MongoDB 6.0+
- **二维码**: QRCode.js + jsQR

## 🔧 维护说明

### 日常运维
```bash
# 查看应用状态
sudo systemctl status barrel-management

# 查看实时日志
sudo journalctl -u barrel-management -f

# 重启服务
sudo systemctl restart barrel-management
```

### 故障排查
参考 `DEPLOYMENT_TROUBLESHOOTING.md` 文档获取详细的故障排除指南。