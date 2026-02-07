module.exports = {
  // 阿里云ECS部署配置
  ecs: {
    region: 'cn-hangzhou', // 阿里云区域
    instanceType: 'ecs.t5-lc1m2.small', // 实例类型
    imageId: 'ubuntu_20_04_x64_20G_alibase_20210420.vhd', // 镜像ID
    securityGroupId: '', // 安全组ID
    vSwitchId: '', // 交换机ID
    keyPairName: '', // 密钥对名称
  },
  
  // 应用配置
  app: {
    name: 'barrel-management-system',
    port: 3000,
    domain: 'your-domain.com', // 你的域名
    ssl: true, // 是否启用SSL
  },
  
  // 数据库配置
  database: {
    type: 'mongodb', // 或 'sqlite'
    host: 'localhost',
    port: 27017,
    name: 'barrelManagement',
    username: '',
    password: '',
  },
  
  // 部署脚本
  deployScript: `
#!/bin/bash
# 部署脚本

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

# 创建应用目录
mkdir -p /var/www/barrel-management
cd /var/www/barrel-management

# 这里需要上传应用代码
# scp -r ./* user@your-server:/var/www/barrel-management/

# 安装依赖
npm install --production

# 创建systemd服务文件
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

# 配置Nginx反向代理
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

echo "部署完成！"
`,
  
  // 阿里云容器服务配置（可选）
  acs: {
    clusterName: 'barrel-management-cluster',
    namespace: 'default',
    image: 'registry.cn-hangzhou.aliyuncs.com/your-namespace/barrel-management:latest',
    replicas: 1,
    cpu: '0.5',
    memory: '512Mi',
  }
};