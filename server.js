const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const multer = require('multer');
const sharp = require('sharp');
const { createCanvas } = require('canvas');
const QRCode = require('qrcode');

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件配置
app.use(cors());
app.use(bodyParser.json());

// 修复静态文件服务配置 - 使用绝对路径确保正确加载
const path = require('path');
const __dirname = path.dirname(require.main.filename);
app.use(express.static(path.join(__dirname, '.'))); // 使用绝对路径

// MongoDB连接配置
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/barrelManagement';

mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
});

// 桶模型定义
const barrelSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  status: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const Barrel = mongoose.model('Barrel', barrelSchema);

// 文件上传配置
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// API路由

// 获取所有桶
app.get('/api/barrels', async (req, res) => {
  try {
    const barrels = await Barrel.find().sort({ createdAt: -1 });
    res.json(barrels);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 启动服务器 - 绑定到所有网络接口
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 服务器运行在端口 ${PORT}`);
  console.log(`🌐 访问地址: http://0.0.0.0:${PORT}`);
});
