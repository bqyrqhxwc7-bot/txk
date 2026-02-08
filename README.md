# 桶管理系统

一个现代化的桶管理系统，支持二维码生成、扫描和状态跟踪功能。

## 功能特性

- 📱 响应式Web界面
- 🏷️ 二维码生成和下载
- 🔍 二维码扫描识别
- 🔄 实时状态更新
- 💾 数据持久化存储
- ☁️ 云端部署支持

## 技术栈

### 前端
- HTML5 + CSS3
- JavaScript (ES6+)
- QRCode.js (二维码生成)
- jsQR (二维码扫描)

### 后端
- Node.js + Express (v14.17.0+)
- MongoDB (数据存储)
- Mongoose (ODM)

### 部署
- Docker + Docker Compose
- Nginx (反向代理)
- 阿里云ECS/ACK

## 快速开始

### 本地开发

1. **克隆项目**
```bash
git clone <repository-url>
cd TX
```

2. **安装依赖**
```bash
npm install
```

3. **启动MongoDB**
```bash
# 确保MongoDB服务正在运行
sudo systemctl start mongod
```

4. **启动应用**
```bash
npm start
# 或开发模式
npm run dev
```

5. **访问应用**
打开浏览器访问 `http://localhost:3000`

### Docker部署

```bash
# 构建并启动
docker-compose up -d

# 查看日志
docker-compose logs -f
```

## API接口

### 桶管理
- `GET /api/barrels` - 获取所有桶
- `POST /api/barrels` - 添加新桶
- `PUT /api/barrels/:id` - 更新桶状态
- `DELETE /api/barrels/:id` - 删除桶

### 二维码操作
- `GET /api/barrels/:id/qrcode` - 生成并下载二维码

### 工具接口
- `POST /api/scan-qrcode` - 扫描二维码图片
- `GET /health` - 健康检查

## 项目结构

```
TX/
├── index.html          # 主页面
├── script.js           # 前端逻辑
├── style.css           # 样式文件
├── server.js           # 后端服务器
├── package.json        # 项目依赖
├── Dockerfile          # Docker配置
├── docker-compose.yml  # Docker编排
├── nginx.conf          # Nginx配置
├── .env               # 环境变量
├── deploy-config.js   # 部署配置
├── DEPLOYMENT.md      # 部署指南
└── README.md          # 项目说明
```

## 部署到阿里云

详细部署说明请参考 [DEPLOYMENT.md](DEPLOYMENT.md)

### 简单部署步骤

1. 准备阿里云ECS实例
2. 上传项目代码到服务器
3. 执行部署脚本
4. 配置域名和SSL证书

## 详细配置指南

### 1. Node.js版本要求

**重要提示**：本项目需要Node.js版本 ≥ 14.17.0

#### 推荐版本：
- **生产环境**: Node.js 18 LTS (推荐)
- **开发环境**: Node.js 16 LTS 或 18 LTS

#### 版本检查：
```bash
# 检查当前Node.js版本
node --version
npm --version

# 预期输出示例：
# v18.17.1
# 9.6.7
```

#### 版本升级指南：

**Windows系统**:
1. 访问 [Node.js官网](https://nodejs.org/zh-cn/download/)
2. 下载并安装 **LTS版本**（长期支持版本）
3. 重启命令提示符或VS Code

**Linux系统**:
```bash
# 使用NodeSource安装Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 或使用nvm管理多个版本
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install --lts
nvm use --lts
```

**Mac系统**:
```bash
# 使用Homebrew
brew install node

# 或使用nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.zshrc
nvm install --lts
nvm use --lts
```

### 2. MongoDB安装指南（修复apt-key弃用问题）

#### Ubuntu 20.04+ 和 Debian 11+ 系统

由于`apt-key`已被弃用，使用以下新方法安装MongoDB：

```bash
# 1. 创建密钥环目录
sudo mkdir -p /etc/apt/keyrings

# 2. 下载并安装GPG密钥（新方法）
curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | \
   sudo gpg --dearmor -o /etc/apt/keyrings/mongodb-server-6.0.gpg

# 3. 添加MongoDB仓库源
echo "deb [ arch=amd64, signed-by=/etc/apt/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# 4. 更新包列表并安装
sudo apt-get update
sudo apt-get install -y mongodb-org

# 5. 启动MongoDB服务
sudo systemctl start mongod
sudo systemctl enable mongod
```

#### 验证安装
```bash
# 检查MongoDB服务状态
systemctl status mongod

# 测试连接
mongo --eval "db.version()"
```

### 3. 环境变量配置 (.env文件)

创建 `.env` 文件并配置以下参数：

```env
# 应用配置
PORT=3000                    # 应用监听端口
NODE_ENV=development         # 运行环境: development | production

# 数据库配置
MONGODB_URI=mongodb://localhost:27017/barrelManagement  # MongoDB连接字符串
MONGODB_USERNAME=            # MongoDB用户名（可选）
MONGODB_PASSWORD=            # MongoDB密码（可选）

# 安全配置
CORS_ORIGINS=http://localhost:3000,https://your-domain.com  # 允许的跨域来源
JWT_SECRET=your-jwt-secret-key  # JWT密钥（用于认证）

# 二维码配置
QR_CODE_SIZE=256             # 二维码尺寸（像素）
QR_CODE_ERROR_CORRECTION=L   # 错误纠正级别: L/M/Q/H
QR_CODE_MARGIN=4             # 二维码边距

# 日志配置
LOG_LEVEL=info               # 日志级别: debug/info/warn/error
LOG_FORMAT=json              # 日志格式: json/text
```

**注意**：`.env` 文件不应提交到版本控制系统，已在 `.gitignore` 中配置忽略

### 4. 服务器配置 (server.js)

主要配置项在 `server.js` 文件中：

```javascript
// 服务器配置
const config = {
  port: process.env.PORT || 3000,
  mongodb: {
    uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/barrelManagement',
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000
    }
  },
  cors: {
    origin: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3000'],
    credentials: true
  },
  qrcode: {
    size: parseInt(process.env.QR_CODE_SIZE) || 256,
    errorCorrectionLevel: process.env.QR_CODE_ERROR_CORRECTION || 'L',
    margin: parseInt(process.env.QR_CODE_MARGIN) || 4
  }
};
```

### 5. Docker配置

#### Dockerfile 配置说明
```dockerfile
# 使用Node.js 18 LTS基础镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 复制package.json和package-lock.json
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 3000

# 启动命令
CMD ["npm", "start"]
```

#### docker-compose.yml 配置说明
```yaml
version: '3.8'
services:
  mongo:
    image: mongo:6.0
    container_name: barrel-mongo
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: example

  app:
    build: .
    container_name: barrel-app
    ports:
      - "3000:3000"
    depends_on:
      - mongo
    environment:
      - NODE_ENV=production
      - PORT=3000
      - MONGODB_URI=mongodb://mongo:27017/barrelManagement
      - MONGODB_USERNAME=root
      - MONGODB_PASSWORD=example
    volumes:
      - ./uploads:/app/uploads

volumes:
  mongo-data:
```

### 6. Nginx配置 (nginx.conf)

```nginx
# 生产环境Nginx配置
server {
    listen 80;
    server_name _;

    # 静态文件缓存
    location /static {
        alias /app/public;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API代理
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
    }

    # 前端路由
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # 错误页面
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
```

### 7. 阿里云部署配置

#### ECS实例配置建议
- **操作系统**: Ubuntu 20.04 LTS 或 CentOS 7+
- **CPU**: 2核以上
- **内存**: 4GB以上
- **磁盘**: 50GB SSD以上
- **网络**: 公网带宽 ≥ 1Mbps

#### 部署步骤

1. **准备ECS实例**
   ```bash
   # 登录ECS实例
   ssh root@your-ecs-ip
   
   # 安装必要软件
   apt update && apt upgrade -y
   apt install -y git curl wget
   ```

2. **安装Node.js和MongoDB**
   ```bash
   # 安装Node.js 18
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   apt install -y nodejs
   
   # 安装MongoDB（新方法，避免apt-key弃用问题）
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | sudo gpg --dearmor -o /etc/apt/keyrings/mongodb-server-6.0.gpg
   echo "deb [ arch=amd64, signed-by=/etc/apt/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
   sudo apt-get update
   sudo apt-get install -y mongodb-org
   sudo systemctl start mongod
   sudo systemctl enable mongod
   ```

3. **部署应用**
   ```bash
   # 克隆项目
   git clone https://github.com/your-repo/barrel-management.git
   cd barrel-management
   
   # 安装依赖
   npm install --production
   
   # 创建环境配置
   cp .env.example .env
   
   # 启动应用
   npm start
   ```

4. **配置Nginx反向代理**
   ```bash
   # 安装Nginx
   apt install -y nginx
   
   # 配置站点
   cp nginx.conf /etc/nginx/sites-available/barrel-management
   ln -sf /etc/nginx/sites-available/barrel-management /etc/nginx/sites-enabled/
   nginx -t && systemctl restart nginx
   ```

### 8. 二维码命名规范验证

根据项目规范，二维码文件名必须遵循 `桶ID+QR.png` 格式：
- ✅ 正确示例: `桶001QR.png`, `桶A123QR.png`
- ❌ 错误示例: `barrel_001.png`, `qrcode_123.jpg`

前端代码中已实现此规范：
```javascript
// 在 generateAndSaveQRCode 函数中
a.download = `${barrelId}QR.png`; // 符合命名规范
```

### 9. 故障排除

#### 常见问题解决

1. **数据库连接失败**
   - 检查MongoDB服务是否运行：`systemctl status mongod`
   - 检查连接字符串是否正确
   - 检查防火墙设置：`ufw allow 27017`

2. **API请求404**
   - 检查服务器是否正常启动
   - 检查路由配置是否正确
   - 查看服务器日志：`journalctl -u barrel-management -f`

3. **二维码无法生成**
   - 检查QRCode库是否正确加载
   - 检查桶ID格式是否符合要求
   - 检查服务器是否有写入权限

#### 常见部署问题

1. **Git克隆失败**
   ```
   error: RPC failed; curl 16 Error in the HTTP2 framing layer
   ```
   **解决方案**: 
   ```bash
   curl -O https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/git-clone-fix.sh
   chmod +x git-clone-fix.sh
   sudo ./git-clone-fix.sh
   ```

2. **目录清理错误**
   ```
   find: '/var/www/barrel-management': No such file or directory
   ```
   **解决方案**: 运行修复脚本
   ```bash
   curl -O https://raw.githubusercontent.com/bqyrqhxwc7-bot/txk/main/fix-deployment.sh
   chmod +x fix-deployment.sh
   sudo ./fix-deployment.sh
   ```

3. **Node.js版本问题**
   ```bash
   Error: The module 'sharp' was compiled against a different Node.js version
   ```
   **解决方案**: 
   - 升级到Node.js 18 LTS
   - 重新安装依赖: `npm install --force`

4. **MongoDB连接失败**
   ```
   MongoServerSelectionError: connect ECONNREFUSED
   ```
   **解决方案**:
   ```bash
   sudo systemctl status mongod
   sudo systemctl restart mongod
   ```

5. **权限问题**
   ```
   EACCES: permission denied
   ```
   **解决方案**:
   ```bash
   sudo chown -R $USER:$USER /var/www/barrel-management
   sudo chmod -R 755 /var/www/barrel-management
   ```

#### 系统要求检查
```bash
# 检查Node.js版本
node --version  # 应该 >= 14.17.0

# 检查MongoDB状态
sudo systemctl status mongod

# 检查端口占用
sudo netstat -tlnp | grep :3000
```

## 开发指南

### 代码规范
- 使用ES6+语法
- 遵循RESTful API设计
- 前后端分离架构

### 贡献流程
1. Fork项目
2. 创建功能分支
3. 提交更改
4. 发起Pull Request

## 许可证

MIT License

## 联系方式

如有问题请联系：[your-email@example.com]