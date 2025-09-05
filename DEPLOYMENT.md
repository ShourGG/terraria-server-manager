# 🎮 泰拉瑞亚服务器管理面板 - 部署指南

## 📋 问题说明

**重要提醒**：原始的 `deploy.sh` 脚本试图从GitHub Release下载文件，但由于以下原因可能失败：

1. ❌ **GitHub Release文件问题** - Release中的文件可能不完整或损坏
2. ❌ **网络下载限制** - 某些服务器环境下载GitHub文件可能失败
3. ❌ **依赖外部资源** - 依赖GitHub API和网络连接

## ✅ 推荐解决方案

### 方案1：本地部署脚本（最稳定）

使用 `deploy-local.sh` 脚本，直接使用项目中的文件：

```bash
# 1. 克隆项目
git clone https://github.com/ShourGG/terraria-server-manager.git
cd terraria-server-manager

# 2. 运行本地部署脚本
chmod +x deploy-local.sh
./deploy-local.sh
```

**优势**：
- ✅ 不依赖GitHub Release下载
- ✅ 使用项目中已有的文件
- ✅ 更快的部署速度
- ✅ 更高的成功率

### 方案2：手动部署（最可控）

如果脚本仍有问题，可以手动部署：

```bash
# 1. 克隆项目
git clone https://github.com/ShourGG/terraria-server-manager.git
cd terraria-server-manager

# 2. 创建安装目录
mkdir -p ~/terraria-panel

# 3. 复制文件
cp -r temp-linux/* ~/terraria-panel/
cp -r dist ~/terraria-panel/ 2>/dev/null || true

# 4. 设置权限
chmod +x ~/terraria-panel/terraria-panel

# 5. 启动服务
cd ~/terraria-panel
nohup ./terraria-panel > terraria-panel.log 2>&1 &
echo $! > terraria-panel.pid

# 6. 检查状态
ps aux | grep terraria-panel
```

### 方案3：直接使用Python HTTP服务器

如果编译的程序有问题，可以直接使用Python：

```bash
# 1. 进入项目目录
cd terraria-server-manager

# 2. 启动Python HTTP服务器
cd dist  # 如果有前端文件
python3 -m http.server 8090 --bind 0.0.0.0

# 或者在项目根目录
python3 -m http.server 8090 --bind 0.0.0.0
```

## 🔧 故障排除

### 问题1：deploy.sh下载失败

**错误信息**：
```
curl: (22) The requested URL returned error: 404 Not Found
```

**解决方案**：
使用 `deploy-local.sh` 替代 `deploy.sh`

### 问题2：程序启动失败

**检查步骤**：
```bash
# 检查文件是否存在
ls -la ~/terraria-panel/terraria-panel

# 检查文件权限
chmod +x ~/terraria-panel/terraria-panel

# 查看错误日志
cat ~/terraria-panel/terraria-panel.log

# 手动启动测试
cd ~/terraria-panel
./terraria-panel
```

### 问题3：端口无法访问

**检查步骤**：
```bash
# 检查端口监听
netstat -tlnp | grep 8090
# 或
ss -tlnp | grep 8090

# 检查进程状态
ps aux | grep -E "(terraria-panel|python3.*8090)"

# 测试本地访问
curl -I http://localhost:8090

# 检查防火墙
sudo ufw status
```

## 📝 部署验证

部署完成后，进行以下验证：

### 1. 服务状态检查
```bash
# 检查进程
ps aux | grep terraria-panel

# 检查端口
netstat -tlnp | grep 8090

# 检查日志
tail -f ~/terraria-panel/terraria-panel.log
```

### 2. 访问测试
```bash
# 本地访问测试
curl -I http://localhost:8090

# 获取公网IP
curl -s ifconfig.me

# 公网访问测试（在浏览器中）
# http://你的公网IP:8090
```

### 3. 功能验证
- ✅ 能够访问Web界面
- ✅ 前端文件加载正常
- ✅ 后端API响应正常
- ✅ WebSocket连接正常

## 🚀 生产环境部署建议

### 1. 使用systemd服务
```bash
# 创建服务文件
sudo tee /etc/systemd/system/terraria-panel.service > /dev/null <<EOF
[Unit]
Description=Terraria Server Management Panel
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/terraria-panel
ExecStart=$HOME/terraria-panel/terraria-panel
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable terraria-panel
sudo systemctl start terraria-panel
```

### 2. 配置反向代理（可选）
```nginx
# Nginx配置示例
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:8090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3. 安全配置
- 配置防火墙规则
- 使用HTTPS（SSL证书）
- 设置访问控制
- 定期备份数据

## 📞 技术支持

如果遇到问题，请提供以下信息：

1. **系统信息**：`uname -a`
2. **错误日志**：`cat ~/terraria-panel/terraria-panel.log`
3. **进程状态**：`ps aux | grep terraria`
4. **端口状态**：`netstat -tlnp | grep 8090`
5. **部署方式**：使用的哪个脚本或方法

---

**老王暴躁技术流** 出品 🔥
