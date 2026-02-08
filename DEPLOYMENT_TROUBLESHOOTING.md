# 🛠️ 部署问题解决指南

## 🔧 Git克隆相关问题

### 问题1: 克隆失败且重试次数不足
```
🔄 尝试第 1 次克隆...
⚠️  克隆失败，1秒后重试...
🔄 尝试第 2 次克隆...
⚠️  克隆失败0，2秒后重试...
❌ 多次尝试克隆失败
```

**原因**: 原始部署脚本的重试策略过于激进（3次重试，短等待时间），不适合网络不稳定环境

**解决方案**: 使用增强版修复脚本

#### 方法一: 使用增强版修复脚本（推荐）
```bash
# 下载增强版修复脚本
curl -O https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/enhanced-git-fix.sh
chmod +x enhanced-git-fix.sh
sudo ./enhanced-git-fix.sh
```

**增强特性**:
- ✅ 6次重试机会（原为3次）
- ✅ 指数退避等待（3s→6s→12s→24s→30s→30s）
- ✅ 多种克隆方法尝试（浅克隆、HTTP/1.1等）
- ✅ 自动备用方案（zip下载、tar.gz下载、最小化项目创建）
- ✅ 详细的网络诊断

#### 方法二: 手动优化重试策略
```
# 在服务器上执行
cd /var/www/barrel-management

# 设置更合理的Git配置
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
git config --global http.version HTTP/1.1
git config --global core.compression 0

# 手动重试（等待更长时间）
for i in {1..6}; do
    echo "尝试第 $i 次..."
    if git clone https://github.com/bqyrqhxwc7-bot/txk.git .; then
        echo "成功！"
        break
    else
        wait_time=$((3 * (2 ** ($i - 1))))
        if [ $wait_time -gt 30 ]; then wait_time=30; fi
        echo "等待 ${wait_time} 秒..."
        sleep $wait_time
    fi
done
```

### 问题2: 前端文件缺失导致"有服务无内容"
```
ls: cannot access 'index.html': No such file or directory
```

**解决方案**: 确保完整部署所有文件
- 使用增强版脚本自动创建最小化前端
- 或手动上传前端文件
- 或使用zip/tar.gz方式完整下载项目

## 🔧 服务启动问题诊断

### 关键检查清单
1. **文件完整性**: `ls -la index.html style.css script.js server.js`
2. **端口监听**: `netstat -tlnp | grep :3000`
3. **防火墙**: `ufw status` 和云服务器安全组
4. **绑定地址**: 确认server.js中使用 `app.listen(PORT, '0.0.0.0')`
5. **依赖安装**: `npm install --production`

### 紧急恢复步骤
```bash
# 1. 停止服务
systemctl stop barrel-management

# 2. 清理并重新部署
rm -rf /var/www/barrel-management/*
cd /var/www/barrel-management

# 3. 使用增强脚本部署
curl -O https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/enhanced-git-fix.sh
chmod +x enhanced-git-fix.sh
sudo ./enhanced-git-fix.sh

# 4. 启动服务
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