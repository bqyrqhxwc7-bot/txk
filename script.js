let barrels = [];
const API_BASE_URL = '/api';

// 页面加载时读取数据
window.onload = function() {
    loadBarrels();
    renderBarrelList();
};

// 不再需要页面关闭时保存数据，因为数据会实时通过API保存
// window.onbeforeunload 已移除

async function loadBarrels() {
    try {
        const response = await fetch(`${API_BASE_URL}/barrels`);
        if (response.ok) {
            barrels = await response.json();
        } else {
            console.error('获取桶列表失败:', await response.text());
        }
    } catch (error) {
        console.error('网络错误:', error);
        // 如果API不可用，使用本地存储作为后备
        const savedBarrels = localStorage.getItem('barrels');
        if (savedBarrels) {
            barrels = JSON.parse(savedBarrels);
        }
    }
}

async function saveBarrels() {
    // 数据已经通过API实时保存，这里只需要更新UI
    renderBarrelList();
}

async function createDataFolder() {
    // 服务器端会自动处理数据持久化
    console.log('数据已保存到服务器');
}

async function generateAndSaveQRCode(barrelId) {
    try {
        // 直接下载服务器生成的二维码
        const response = await fetch(`${API_BASE_URL}/barrels/${barrelId}/qrcode`);
        if (response.ok) {
            const blob = await response.blob();
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `${barrelId}QR.png`; // 符合命名规范：桶ID+QR
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        } else {
            console.error('生成二维码失败:', await response.text());
            // 备用方案：使用客户端生成
            generateQRClientSide(barrelId);
        }
    } catch (error) {
        console.error('网络错误，使用备用方案:', error);
        generateQRClientSide(barrelId);
    }
}

function generateQRClientSide(barrelId) {
    // 客户端生成二维码的备用方案
    QRCode.toCanvas(document.createElement('canvas'), barrelId, function (error, canvas) {
        if (error) {
            console.error(error);
            return;
        }
        
        canvas.toBlob(function(blob) {
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `${barrelId}QR.png`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        });
    });
}

function renderBarrelList() {
    const barrelList = document.getElementById('barrels');
    barrelList.innerHTML = '';
    barrels.forEach(barrel => {
        const li = document.createElement('li');
        li.textContent = `桶ID: ${barrel.id}, 状态: ${barrel.status}`;
        li.onclick = () => showBarrelDetail(barrel.id);
        barrelList.appendChild(li);
    });
}

async function showBarrelDetail(barrelId) {
    const barrel = barrels.find(b => b.id === barrelId);
    if (barrel) {
        document.getElementById('barrel-id').textContent = barrel.id;
        document.getElementById('barrel-status').textContent = barrel.status;
        document.getElementById('status-select').value = barrel.status;
        document.getElementById('main-menu').style.display = 'none';
        document.getElementById('barrel-list').style.display = 'none';
        document.getElementById('barrel-detail').style.display = 'block';
        
        // 显示二维码下载按钮
        const qrDownloadBtn = document.getElementById('download-qr-btn');
        if (qrDownloadBtn) {
            qrDownloadBtn.style.display = 'inline-block';
            qrDownloadBtn.onclick = () => downloadQRCode(barrelId);
        }
    }
}

document.getElementById('add-barrel-btn').onclick = function() {
    document.getElementById('main-menu').style.display = 'none';
    document.getElementById('barrel-list').style.display = 'none';
    document.getElementById('add-barrel-form').style.display = 'block';
};

document.getElementById('scan-qr-btn').onclick = function() {
    document.getElementById('main-menu').style.display = 'none';
    document.getElementById('barrel-list').style.display = 'none';
    document.getElementById('scan-qr-form').style.display = 'block';
};

document.getElementById('save-barrel-btn').onclick = async function() {
    const id = document.getElementById('new-barrel-id').value;
    const status = document.getElementById('new-barrel-status').value;
    if (id && status) {
        try {
            const response = await fetch(`${API_BASE_URL}/barrels`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ id, status })
            });
            
            if (response.ok) {
                const newBarrel = await response.json();
                barrels.push(newBarrel);
                renderBarrelList();
                showMainMenu();
                document.getElementById('new-barrel-id').value = '';
            } else {
                const error = await response.json();
                alert('添加失败: ' + error.error);
            }
        } catch (error) {
            console.error('网络错误:', error);
            alert('网络错误，请稍后重试');
        }
    }
};

document.getElementById('cancel-add-btn').onclick = showMainMenu;

document.getElementById('update-status-btn').onclick = async function() {
    const barrelId = document.getElementById('barrel-id').textContent;
    const newStatus = document.getElementById('status-select').value;
    
    try {
        const response = await fetch(`${API_BASE_URL}/barrels/${barrelId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ status: newStatus })
        });
        
        if (response.ok) {
            const updatedBarrel = await response.json();
            const barrelIndex = barrels.findIndex(b => b.id === barrelId);
            if (barrelIndex !== -1) {
                barrels[barrelIndex] = updatedBarrel;
            }
            renderBarrelList();
            showBarrelDetail(barrelId);
        } else {
            const error = await response.json();
            alert('更新失败: ' + error.error);
        }
    } catch (error) {
        console.error('网络错误:', error);
        alert('网络错误，请稍后重试');
    }
};

document.getElementById('delete-barrel-btn').onclick = async function() {
    const barrelId = document.getElementById('barrel-id').textContent;
    
    if (confirm('确定要删除这个桶吗？')) {
        try {
            const response = await fetch(`${API_BASE_URL}/barrels/${barrelId}`, {
                method: 'DELETE'
            });
            
            if (response.ok) {
                barrels = barrels.filter(b => b.id !== barrelId);
                renderBarrelList();
                showMainMenu();
            } else {
                const error = await response.json();
                alert('删除失败: ' + error.error);
            }
        } catch (error) {
            console.error('网络错误:', error);
            alert('网络错误，请稍后重试');
        }
    }
};

document.getElementById('back-btn').onclick = showMainMenu;

document.getElementById('process-qr-btn').onclick = function() {
    const fileInput = document.getElementById('qr-image-input');
    if (fileInput.files && fileInput.files[0]) {
        const reader = new FileReader();
        reader.onload = function(e) {
            // 使用jsQR库解析二维码
            const img = new Image();
            img.onload = function() {
                const canvas = document.createElement('canvas');
                const ctx = canvas.getContext('2d');
                canvas.width = img.width;
                canvas.height = img.height;
                ctx.drawImage(img, 0, 0);
                
                const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
                const code = jsQR(imageData.data, imageData.width, imageData.height);
                
                if (code) {
                    showBarrelDetail(code.data);
                } else {
                    alert('无法识别二维码，请确保图片清晰且包含有效的二维码。');
                }
            };
            img.src = e.target.result;
        };
        reader.readAsDataURL(fileInput.files[0]);
    }
};

document.getElementById('cancel-scan-btn').onclick = showMainMenu;

async function downloadQRCode(barrelId) {
    // 下载服务器生成的二维码
    await generateAndSaveQRCode(barrelId);
}

function showMainMenu() {
    document.getElementById('main-menu').style.display = 'block';
    document.getElementById('barrel-list').style.display = 'block';
    document.getElementById('barrel-detail').style.display = 'none';
    document.getElementById('add-barrel-form').style.display = 'none';
    document.getElementById('scan-qr-form').style.display = 'none';
    
    // 清空表单
    document.getElementById('new-barrel-id').value = '';
    document.getElementById('qr-image-input').value = '';
    
    // 隐藏二维码下载按钮
    const qrDownloadBtn = document.getElementById('download-qr-btn');
    if (qrDownloadBtn) {
        qrDownloadBtn.style.display = 'none';
    }
}