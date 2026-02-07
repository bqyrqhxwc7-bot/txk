# 项目结构说明

## 文件结构

```
TX/
│
├── 前端文件
│   ├── index.html          # 主页面HTML
│   ├── script.js           # 前端JavaScript逻辑
│   └── style.css           # CSS样式文件
│
├── 后端文件
│   ├── server.js           # Node.js Express服务器
│   └── package.json        # Node.js依赖配置
│
├── 部署配置
│   ├── Dockerfile          # Docker镜像构建文件
│   ├── docker-compose.yml  # Docker容器编排配置
│   ├── nginx.conf          # Nginx反向代理配置
│   ├── deploy.sh           # 一键部署脚本
│   └── deploy-config.js    # 部署配置参数
│
├── 环境配置
│   ├── .env               # 环境变量配置
│   └── .gitignore         # Git忽略文件配置
│
└── 文档文件
    ├── README.md          # 项目说明文档
    ├── DEPLOYMENT.md      # 详细部署指南
    └── PROJECT_STRUCTURE.md  # 项目结构说明
```

## 核心组件说明

### 前端组件
- **index.html**: 单页面应用程序入口，包含所有UI元素
- **script.js**: 实现前后端交互逻辑，包括：
  - API调用封装
  - UI事件处理
  - 二维码生成和扫描
  - 数据展示和表单处理
- **style.css**: 响应式样式设计

### 后端组件
- **server.js**: Express服务器，提供：
  - RESTful API接口
  - 静态文件服务
  - 数据库操作
  - 二维码生成服务
- **package.json**: 项目依赖管理

### 部署组件
- **Dockerfile**: 容器化应用构建配置
- **docker-compose.yml**: 多容器应用编排
- **nginx.conf**: 生产环境反向代理配置
- **deploy.sh**: 自动化部署脚本

## 数据流向

```
用户操作 → 前端JS → API请求 → 后端服务器 → MongoDB
                                      ↓
                                二维码生成 ← 返回数据
```

## API端点

### 桶管理API
- `GET /api/barrels` - 获取桶列表
- `POST /api/barrels` - 创建新桶
- `PUT /api/barrels/:id` - 更新桶状态
- `DELETE /api/barrels/:id` - 删除桶

### 二维码API
- `GET /api/barrels/:id/qrcode` - 生成二维码图片

### 工具API
- `POST /api/scan-qrcode` - 图片二维码识别
- `GET /health` - 服务健康检查

## 部署架构

### 开发环境
```
浏览器 → Node.js服务器 → MongoDB
```

### 生产环境
```
用户 → Nginx → Node.js应用 → MongoDB
       (负载均衡/SSL)  (API服务)   (数据存储)
```

## 安全考虑

1. **CORS配置**: 限制跨域请求来源
2. **输入验证**: 后端数据校验
3. **HTTPS支持**: SSL/TLS加密传输
4. **环境隔离**: 开发/测试/生产环境分离

## 性能优化

1. **静态资源缓存**: Nginx缓存配置
2. **数据库索引**: MongoDB查询优化
3. **连接池**: 数据库连接复用
4. **压缩传输**: Gzip/Brotli压缩

## 扩展性设计

1. **微服务架构**: 可拆分为独立服务
2. **消息队列**: 异步任务处理
3. **缓存层**: Redis缓存热点数据
4. **负载均衡**: 多实例部署支持