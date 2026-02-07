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
- Node.js + Express
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

## 配置说明

### 环境变量
```env
PORT=3000                    # 应用端口
NODE_ENV=production         # 运行环境
MONGODB_URI=mongodb://localhost:27017/barrelManagement  # 数据库连接
```

### 二维码命名规范
下载的二维码文件遵循 `桶ID+QR.png` 的命名格式，例如：`桶001QR.png`

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