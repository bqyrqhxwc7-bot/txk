# 桶管理系统部署指南

## 部署选项

### 1. 阿里云ECS部署

#### 准备工作
1. 注册阿里云账号
2. 购买ECS实例（推荐配置：2核4GB内存）
3. 配置安全组规则，开放端口80、443、22
4. 绑定弹性公网IP

#### 部署步骤

1. **连接到ECS实例**
```bash
ssh root@172.24.92.188
```

2. **执行部署脚本**
```bash
# 下载部署脚本
wget https://github.com/bqyrqhxwc7-bot/txk/blob/main/deploy.sh

# 修改权限并执行
chmod +x deploy.sh
./deploy.sh
```

3. **手动部署步骤**
```bash
# 更新系统
apt update && apt upgrade -y

# 安装Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs

# 安装MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server_6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
apt update
apt install -y mongodb-org

# 启动MongoDB
systemctl start mongod
systemctl enable mongod

# 上传应用代码到服务器
scp -r ./ root@your-server-ip:/var/www/barrel-management/

# 安装应用依赖
cd /var/www/barrel-management
npm install --production

# 创建systemd服务
cat > /etc/systemd/system/barrel-management.service << EOF
[Unit]
Description=Barrel Management System
After=network.target mongod.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/barrel-management
ExecStart=/usr/bin/node server.js
Restart=always
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=MONGODB_URI=mongodb://localhost:27017/barrelManagement

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
systemctl daemon-reload
systemctl start barrel-management
systemctl enable barrel-management
```

4. **配置Nginx反向代理**
```bash
apt install -y nginx

cat > /etc/nginx/sites-available/barrel-management << EOF
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -s /etc/nginx/sites-available/barrel-management /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

### 2. Docker容器化部署

#### 本地测试
```bash
# 构建镜像
docker build -t barrel-management .

# 运行容器
docker run -p 3000:3000 barrel-management
```

#### 生产环境部署
```bash
# 使用Docker Compose
docker-compose up -d

# 查看日志
docker-compose logs -f
```

### 3. 阿里云容器服务(Kubernetes)部署

1. **推送镜像到阿里云容器镜像服务**
```bash
# 登录阿里云容器镜像服务
docker login registry.cn-hangzhou.aliyuncs.com

# 标记镜像
docker tag barrel-management registry.cn-hangzhou.aliyuncs.com/your-namespace/barrel-management:latest

# 推送镜像
docker push registry.cn-hangzhou.aliyuncs.com/your-namespace/barrel-management:latest
```

2. **部署到Kubernetes集群**
```bash
# 应用Kubernetes配置
kubectl apply -f k8s-deployment.yaml
```

## 环境变量配置

创建 `.env` 文件：
```env
# 应用配置
PORT=3000
NODE_ENV=production

# MongoDB配置
MONGODB_URI=mongodb://localhost:27017/barrelManagement

# 安全配置
SESSION_SECRET=your-secure-session-secret
```

## 域名和SSL配置

### 1. 域名解析
在阿里云DNS控制台添加A记录指向服务器IP

### 2. SSL证书申请
```bash
# 安装Certbot
apt install certbot python3-certbot-nginx

# 申请证书
certbot --nginx -d your-domain.com

# 自动续期
crontab -e
# 添加：0 12 * * * /usr/bin/certbot renew --quiet
```

## 监控和维护

### 日志查看
```bash
# 应用日志
journalctl -u barrel-management -f

# Nginx日志
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### 性能监控
```bash
# 安装htop
apt install htop

# 查看系统资源使用情况
htop
```

### 备份策略
```bash
# MongoDB备份脚本
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mongodump --db barrelManagement --out /backup/mongodb_$DATE
tar -czf /backup/mongodb_$DATE.tar.gz /backup/mongodb_$DATE
rm -rf /backup/mongodb_$DATE
```

## 故障排除

### 常见问题

1. **应用无法启动**
   - 检查端口占用：`lsof -i :3000`
   - 查看服务状态：`systemctl status barrel-management`

2. **数据库连接失败**
   - 检查MongoDB服务：`systemctl status mongod`
   - 验证连接：`mongo mongodb://localhost:27017/barrelManagement`

3. **Nginx配置错误**
   - 测试配置：`nginx -t`
   - 重新加载：`systemctl reload nginx`

### 紧急恢复
```bash
# 重启所有服务
systemctl restart mongod
systemctl restart barrel-management
systemctl restart nginx
```

## 安全建议

1. 使用非root用户运行应用
2. 配置防火墙规则
3. 定期更新系统和软件包
4. 启用SSL/TLS加密
5. 设置适当的文件权限
6. 定期备份重要数据