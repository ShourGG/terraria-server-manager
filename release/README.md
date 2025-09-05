# 🎮 泰拉瑞亚服务器管理面板 v2.0

> 老王暴躁技术流 出品 - 真正能用的泰拉瑞亚服务器管理系统

## ✨ 核心功能

- 🚀 **一键启动泰拉瑞亚服务器** - 自动下载官方服务器文件
- 📊 **实时监控** - CPU、内存、网络状态实时显示
- 👥 **玩家管理** - 在线玩家查看、踢出等操作
- 🌍 **世界管理** - 创建、删除、备份世界文件
- 📝 **日志查看** - 实时查看服务器运行日志
- 🔄 **自动化运维** - 定时重启、自动备份等功能
- 🌐 **Web界面** - 现代化的响应式管理界面
- 🔌 **WebSocket实时通信** - 实时数据推送

## 🚀 Linux一键部署

**最简单的方式：**
```bash
curl -sSL https://raw.githubusercontent.com/ShourGG/terraria-server-manager/main/terraria-panel-upload/deploy-linux.sh | bash
```

**或者手动部署：**
```bash
# 1. 下载项目
git clone https://github.com/ShourGG/terraria-server-manager.git
cd terraria-server-manager/terraria-panel-upload

# 2. 运行部署脚本
chmod +x deploy-linux.sh
./deploy-linux.sh
```

## 💻 Windows快速启动

1. 下载 `terraria-panel-windows.exe`
2. 双击运行
3. 打开浏览器访问 `http://localhost:8090`

## 🐧 Linux手动安装

```bash
# 1. 下载Linux版本
wget https://github.com/ShourGG/terraria-server-manager/releases/latest/download/terraria-panel-linux-new

# 2. 设置权限
chmod +x terraria-panel-linux-new

# 3. 启动服务
./terraria-panel-linux-new
```

## 🌐 访问地址

启动成功后，在浏览器中访问：

- **本地访问**: http://localhost:8090
- **局域网访问**: http://YOUR_IP:8090
- **云服务器**: http://YOUR_SERVER_IP:8090

## 📋 系统要求

### 最低配置
- **CPU**: 1核心
- **内存**: 512MB RAM
- **磁盘**: 1GB 可用空间
- **网络**: 互联网连接（下载服务器文件）

### 推荐配置
- **CPU**: 2核心+
- **内存**: 2GB+ RAM
- **磁盘**: 5GB+ 可用空间
- **网络**: 稳定的互联网连接

### 支持的操作系统
- ✅ **Linux**: Ubuntu 18.04+, CentOS 7+, Debian 9+
- ✅ **Windows**: Windows 10+, Windows Server 2016+
- ✅ **macOS**: macOS 10.14+

## 🎮 使用指南

### 1. 首次启动
1. 启动管理面板
2. 打开浏览器访问管理界面
3. 点击"创建服务器"开始配置

### 2. 创建泰拉瑞亚服务器
1. 填写服务器名称
2. 选择世界大小（小/中/大）
3. 设置最大玩家数
4. 选择难度模式
5. 点击"创建"，系统将自动下载服务器文件

### 3. 服务器管理
- **启动/停止**: 一键控制服务器状态
- **玩家管理**: 查看在线玩家，执行管理操作
- **日志查看**: 实时监控服务器运行状态
- **配置修改**: 动态调整服务器参数

## 🔧 高级配置

### 端口配置
默认端口：8090（管理面板）
泰拉瑞亚服务器端口：7777（可自定义）

### 防火墙设置
确保以下端口开放：
- 8090（管理面板）
- 7777（泰拉瑞亚服务器，可自定义）

### 云服务器部署
1. 在安全组中开放相应端口
2. 确保服务器有足够的内存和磁盘空间
3. 建议使用稳定的网络连接

## 🛠️ 故障排除

### 常见问题

**Q: 无法访问管理面板？**
A: 检查防火墙设置，确保8090端口开放

**Q: 泰拉瑞亚服务器启动失败？**
A: 查看日志文件，通常是端口被占用或权限不足

**Q: 服务器文件下载失败？**
A: 检查网络连接，确保能访问terraria.org

**Q: 内存不足？**
A: 建议至少2GB内存，可以设置虚拟内存

### 日志查看
```bash
# 查看管理面板日志
tail -f ~/terraria-panel/terraria-panel.log

# 查看泰拉瑞亚服务器日志
tail -f ~/terraria-panel/terraria-servers/instances/*/server.log
```

### 重启服务
```bash
# 停止服务
pkill -f terraria-panel

# 启动服务
cd ~/terraria-panel
nohup ./terraria-panel > terraria-panel.log 2>&1 &
```

## 🤝 技术支持

- **GitHub Issues**: https://github.com/ShourGG/terraria-server-manager/issues
- **文档**: https://github.com/ShourGG/terraria-server-manager/wiki
- **老王暴躁技术流**: 专业的技术支持

## 📄 更新日志

### v2.0.0 (2025-09-05)
- ✅ 重构Go后端，性能大幅提升
- ✅ 新增自动下载泰拉瑞亚服务器功能
- ✅ 优化前端界面，提升用户体验
- ✅ 新增一键部署脚本
- ✅ 完善错误处理和日志系统
- ✅ 支持多平台编译和部署

### v1.0.0
- ✅ 基础功能实现
- ✅ Web管理界面
- ✅ 服务器状态监控

## 📜 开源协议

MIT License - 自由使用，欢迎贡献代码

---

**🔥 老王暴躁技术流 出品 - 这才是真正专业的开源项目！**
