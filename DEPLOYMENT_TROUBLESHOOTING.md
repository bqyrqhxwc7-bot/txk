# 🛠️ 部署问题解决指南

本文档提供了桶管理系统部署过程中常见问题的详细解决方案。

## 🔧 Git克隆相关问题

### 问题1: HTTP2 framing layer错误
```
error: RPC failed; curl 16 Error in the HTTP2 framing layer
fatal: error reading section header 'shallow-info'
```

**原因**: 网络不稳定或GitHub服务器HTTP/2协议兼容性问题

**解决方案**:

#### 方法一: 使用修复脚本（推荐）
```bash
curl -O https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/git-clone-fix.sh
chmod +x git-clone-fix.sh
sudo ./git-clone-fix.sh
```

#### 方法二: 手动优化Git配置
```bash
# 以root身份执行
sudo su

cd /var/www/barrel-management

# 优化Git配置
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
git config --global http.version HTTP/1.1
git config --global core.compression 0

# 尝试克隆
git clone https://github.com/bqyrqhxwc7-bot/txk.git .
```

#### 方法三: 使用备用下载方式
```bash
# 使用wget下载zip包
cd /var/www/barrel-management
wget https://github.com/bqyrqhxwc7-bot/txk/archive/main.zip
unzip main.zip
mv txk-main/* ./
mv txk-main/.[^.]* ./ 2>/dev/null || true
rm -rf txk-main main.zip

# 或使用curl下载tar.gz
cd /var/www/barrel-management
curl -L https://github.com/bqyrqhxwc7-bot/txk/archive/main.tar.gz -o main.tar.gz
tar -xzf main.tar.gz
mv txk-main/* ./
mv txk-main/.[^.]* ./ 2>/dev/null || true
rm -rf txk-main main.tar.gz
```

### 问题2: 网络超时错误
```
fatal: unable to access 'https://github.com/...': Failed to connect to github.com port 443
```

**解决方案**:
```bash
# 检查网络连接
ping github.com
traceroute github.com

# 配置代理（如果需要）
git config --global http.proxy http://proxy.server:port
git config --global https.proxy https://proxy.server:port

# 或使用SSH方式克隆（需要配置SSH密钥）
git clone git@github.com:bqyrqhxwc7-bot/txk.git .
```

## 🔧 目录相关问题

### 问题1: `find` 命令报错
```
find: '/var/www/barrel-management': No such file or directory
```

**原因**: 部署脚本在清理已有目录时，由于并发操作或权限问题导致目录在find执行时不存在。

**解决方案**:

#### 方法一: 使用修复脚本（推荐）
```bash
# 下载并运行修复脚本
curl -O https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/fix-deployment.sh
chmod +x fix-deployment.sh
sudo ./fix-deployment.sh

# 然后重新运行部署
curl -O https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/deploy.sh
chmod +x deploy.sh
sudo ./deploy.sh
```

#### 方法二: 手动清理
```bash
# 以root身份执行
sudo su

# 备份重要配置（如果存在）
if [ -f "/var/www/barrel-management/.env" ]; then
    cp /var/www/barrel-management/.env /tmp/env_backup
fi

# 强制删除目录
rm -rf /var/www/barrel-management

# 重新创建目录
mkdir -p /var/www/barrel-management
chmod 755 /var/www/barrel-management

# 恢复配置（如果之前有备份）
if [ -f "/tmp/env_backup" ]; then
    cp /tmp/env_backup /var/www/barrel-management/.env
    rm -f /tmp/env_backup
fi
```

## 🔧 Node.js 相关问题

### 问题2: Sharp模块编译错误
```
Error: The module 'sharp' was compiled against a different Node.js version
```

**解决方案**:
```bash
# 1. 确认Node.js版本
node --version  # 应该显示 v18.x.x

# 2. 如果版本过低，升级Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. 清理并重新安装依赖
cd /var/www/barrel-management
rm -rf node_modules package-lock.json
npm install --force
```

### 问题3: 权限不足错误
```
npm ERR! Error: EACCES: permission denied
```

**解决方案**:
```bash
# 修改npm全局目录权限
sudo chown -R $(whoami) ~/.npm
sudo chown -R $(whoami) /usr/local/lib/node_modules

# 或者使用nvm安装Node.js（推荐）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18
```

## 🔧 MongoDB 相关问题

### 问题4: 数据库连接失败
```
MongoServerSelectionError: connect ECONNREFUSED 127.0.0.1:27017
```

**诊断和解决**:
```bash
# 1. 检查MongoDB服务状态
sudo systemctl status mongod

# 2. 启动MongoDB服务
sudo systemctl start mongod
sudo systemctl enable mongod

# 3. 检查端口监听
sudo netstat -tlnp | grep 27017

# 4. 测试数据库连接
mongosh --eval "db.stats()"
```

### 问题5: 数据库认证失败
```
Authentication failed
```

**解决方案**:
```bash
# 1. 进入MongoDB shell
mongosh

# 2. 切换到admin数据库
use admin

# 3. 创建管理员用户
db.createUser({
  user: "admin",
  pwd: "your_secure_password",
  roles: [{ role: "root", db: "admin" }]
})

# 4. 重启MongoDB启用认证
sudo systemctl restart mongod
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

可以通过GitHub Issues或邮件联系技术支持。