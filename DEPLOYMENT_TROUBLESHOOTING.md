# 🛠️ 部署问题解决指南

本文档提供了桶管理系统部署过程中常见问题的详细解决方案。

## 🔧 依赖相关问题

### 问题1: 缺少canvas模块
```
Error: Cannot find module 'canvas'
```

**原因**: canvas是原生模块，需要系统级依赖支持

**解决方案**:

#### 方法一: 使用修复脚本（推荐）
```bash
curl -O https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/fix-dependencies.sh
chmod +x fix-dependencies.sh
sudo ./fix-dependencies.sh
```

#### 方法二: 手动修复
```bash
# 以root身份执行
sudo su

cd /var/www/barrel-management

# 安装canvas系统依赖
apt update
apt install -y \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev

# 重新安装Node.js依赖
rm -rf node_modules package-lock.json
npm install --production

# 重启服务
systemctl restart barrel-management
```

### 问题2: sharp模块编译失败
```
Error: The module 'sharp' was compiled against a different Node.js version
```

**解决方案**:
```bash
# 安装sharp所需系统依赖
apt install -y \
    libvips-dev \
    libglib2.0-dev \
    libgobject-2.0-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libgif-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libwebp-dev \
    libxml2-dev

# 重新安装依赖
cd /var/www/barrel-management
rm -rf node_modules package-lock.json
npm install --force
```

## 🔧 Git克隆相关问题

### 问题3: HTTP2 framing layer错误
```
error: RPC failed; curl 16 Error in the HTTP2 framing layer
fatal: error reading section header 'shallow-info'
```

**解决方案**: 
参考 [GIT_TROUBLESHOOTING.md](file://c:\Users\sr291\Desktop\TX\GIT_TROUBLESHOOTING.md)

## 🔧 目录相关问题

### 问题4: `find` 命令报错
```
find: '/var/www/barrel-management': No such file or directory
```

**解决方案**: 
参考之前的修复方案

## 🔧 服务启动问题诊断

### 常用检查命令
```bash
# 检查服务状态
systemctl status barrel-management

# 查看实时日志
journalctl -u barrel-management -f

# 检查端口占用
netstat -tlnp | grep :3000

# 测试应用健康检查
curl http://localhost:3000/health

# 验证MongoDB连接
systemctl status mongod
```

### 常见启动失败原因
1. **端口被占用**: 检查是否有其他服务占用3000端口
2. **数据库连接失败**: 确认MongoDB服务运行正常
3. **权限问题**: 检查应用目录权限设置
4. **依赖缺失**: 运行依赖修复脚本
5. **环境变量**: 检查.env配置文件

### 紧急恢复步骤
```bash
# 1. 停止服务
systemctl stop barrel-management

# 2. 检查错误日志
journalctl -u barrel-management --since "10 minutes ago"

# 3. 验证基本环境
node --version
npm --version
systemctl status mongod

# 4. 重新安装依赖
cd /var/www/barrel-management
npm install

# 5. 启动服务
systemctl start barrel-management
```

## 🔧 网络和防火墙问题

### 问题6: 端口访问被拒绝
```
curl: (7) Failed to connect to port 3000
```

**解决方案**:
```bash
# 1. 检查应用是否在运行
sudo systemctl status barrel-management

# 2. 检查端口监听状态
sudo netstat -tlnp | grep :3000

# 3. 配置防火墙
sudo ufw allow 3000
sudo ufw reload

# 4. 检查Nginx配置（如果使用反向代理）
sudo nginx -t
sudo systemctl restart nginx
```

## 🔧 系统资源问题

### 问题7: 内存不足
```
FATAL ERROR: Reached heap limit Allocation failed
```

**解决方案**:
```bash
# 1. 增加Node.js内存限制
export NODE_OPTIONS="--max-old-space-size=2048"

# 2. 或在systemd服务中配置
# 编辑 /etc/systemd/system/barrel-management.service
# 在ExecStart行添加环境变量
# Environment=NODE_OPTIONS=--max-old-space-size=2048

sudo systemctl daemon-reload
sudo systemctl restart barrel-management
```

## 🔧 日志查看和调试

### 查看应用日志
```bash
# 系统日志
sudo journalctl -u barrel-management -f

# 应用控制台输出
sudo systemctl status barrel-management

# MongoDB日志
sudo tail -f /var/log/mongodb/mongod.log
```

### 实时监控
```bash
# 监控系统资源
htop

# 监控网络连接
watch -n 1 'netstat -tlnp | grep :3000'

# 监控磁盘空间
df -h
```

## 🔄 完整重置流程

如果遇到复杂问题，可以执行完整重置：

```bash
#!/bin/bash
# 完整重置脚本

echo "⚠️  警告: 这将删除所有应用数据!"

# 停止服务
sudo systemctl stop barrel-management
sudo systemctl disable barrel-management

# 删除应用目录
sudo rm -rf /var/www/barrel-management

# 删除MongoDB数据（谨慎操作）
# sudo mongosh --eval "db.dropDatabase()" barrelManagement

# 重新部署
curl -O https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/deploy.sh
chmod +x deploy.sh
sudo ./deploy.sh
```

## 💡 最佳实践建议

1. **定期备份**: 定期备份 `.env` 配置文件和MongoDB数据
2. **监控告警**: 设置系统监控和应用健康检查
3. **日志轮转**: 配置日志轮转避免磁盘空间耗尽
4. **安全更新**: 定期更新系统和应用依赖
5. **文档记录**: 记录所有配置变更和问题解决方案

## 📞 获取帮助

如果以上方案都无法解决问题，请提供以下信息：

1. 完整的错误日志
2. 系统环境信息 (`uname -a`)
3. Node.js和npm版本 (`node --version`, `npm --version`)
4. MongoDB版本 (`mongod --version`)
5. 部署脚本的完整执行输出

可以通过GitHub Issues或邮件联系技术支持.