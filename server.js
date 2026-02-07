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
app.use(express.static('.')); // 提供静态文件服务

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

// 添加新桶
app.post('/api/barrels', async (req, res) => {
  try {
    const { id, status } = req.body;
    
    // 检查桶ID是否已存在
    const existingBarrel = await Barrel.findOne({ id });
    if (existingBarrel) {
      return res.status(400).json({ error: '桶ID已存在' });
    }
    
    const barrel = new Barrel({ id, status });
    await barrel.save();
    res.status(201).json(barrel);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 更新桶状态
app.put('/api/barrels/:id', async (req, res) => {
  try {
    const { status } = req.body;
    const barrel = await Barrel.findOneAndUpdate(
      { id: req.params.id },
      { status, updatedAt: Date.now() },
      { new: true }
    );
    
    if (!barrel) {
      return res.status(404).json({ error: '桶未找到' });
    }
    
    res.json(barrel);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 删除桶
app.delete('/api/barrels/:id', async (req, res) => {
  try {
    const barrel = await Barrel.findOneAndDelete({ id: req.params.id });
    if (!barrel) {
      return res.status(404).json({ error: '桶未找到' });
    }
    res.json({ message: '删除成功' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 生成二维码
app.get('/api/barrels/:id/qrcode', async (req, res) => {
  try {
    const barrel = await Barrel.findOne({ id: req.params.id });
    if (!barrel) {
      return res.status(404).json({ error: '桶未找到' });
    }

    // 生成二维码
    const qrCodeBuffer = await QRCode.toBuffer(barrel.id, {
      width: 300,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#ffffff'
      }
    });

    // 设置响应头
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Content-Disposition', `attachment; filename="${barrel.id}QR.png"`);
    res.send(qrCodeBuffer);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 扫描二维码（通过图片上传）
app.post('/api/scan-qrcode', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: '请上传图片文件' });
    }

    // 使用sharp处理图片
    const imageBuffer = req.file.buffer;
    
    // 这里需要集成二维码识别库
    // 由于服务器端二维码识别比较复杂，建议前端处理后发送识别结果
    
    res.json({ message: '图片上传成功，请在前端进行二维码识别' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 健康检查端点
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`服务器运行在端口 ${PORT}`);
  console.log(`访问地址: http://localhost:${PORT}`);
});