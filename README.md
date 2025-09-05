# 🎮 泰拉瑞亚服务器管理面板

一个现代化的泰拉瑞亚服务器管理面板，支持一键部署、自动下载服务器文件、实时监控等功能。

## ✨ 主要功能

- 🚀 **一键部署** - 自动下载官方泰拉瑞亚服务器文件
- 🎯 **跨平台支持** - 支持 Windows 和 Linux 系统
- 📊 **实时监控** - 服务器状态、CPU、内存使用率监控
- 🎮 **服务器管理** - 创建、启动、停止、删除服务器
- 👥 **玩家管理** - 查看在线玩家、踢出玩家等
- 🌐 **现代化界面** - 基于 Vue 3 + TypeScript 的响应式界面
- 🔄 **实时通信** - WebSocket 实时数据更新

## 🛠️ 技术栈

**后端**：
- Go 1.19+
- Gin Web框架
- WebSocket实时通信
- 跨平台文件操作

**前端**：
- Vue 3 + TypeScript
- Vite 构建工具
- Element Plus UI组件
- WebSocket客户端

## 🚀 快速开始

### 方法一：一键部署脚本（推荐）

**Linux/macOS**：
```bash
curl -fsSL https://github.com/your-username/terraria-panel/releases/latest/download/deploy.sh | bash
```

**Windows PowerShell**：
```powershell
iwr -useb https://github.com/your-username/terraria-panel/releases/latest/download/deploy.ps1 | iex
```

### 方法二：手动下载发布版

1. **访问发布页面**：
   前往 [Releases](https://github.com/your-username/terraria-panel/releases) 页面

2. **下载对应平台的压缩包**：
   - **Linux AMD64**: `terraria-panel-linux.tar.gz`
   - **Linux ARM64**: `terraria-panel-linux-arm64.tar.gz`
   - **Windows**: `terraria-panel-windows.zip`
   - **macOS**: `terraria-panel-macos.tar.gz`

3. **解压并运行**：
   ```bash
   # Linux/macOS
   tar -xzf terraria-panel-linux.tar.gz
   cd terraria-panel-linux
   ./start.sh

   # Windows: 解压zip文件后双击 start.bat
   ```

### 方法三：从源码构建（开发者）

> ⚠️ **注意**：源码仅供学习参考，生产环境请使用发布版本

1. **克隆项目**：
```bash
git clone https://github.com/your-username/terraria-panel.git
cd terraria-panel
```

2. **运行构建脚本**：
```bash
chmod +x build.sh
./build.sh
```

3. **使用构建结果**：
```bash
# 发布文件位于 release/ 目录
# 前端文件位于 dist/ 目录
cd release
./terraria-panel-linux  # 或对应平台的可执行文件
```

## 📋 系统要求

- **操作系统**：Windows 10+ 或 Linux (Ubuntu 18.04+, CentOS 7+)
- **内存**：至少 1GB RAM
- **磁盘空间**：至少 500MB 可用空间
- **网络**：需要互联网连接（下载服务器文件）

## 🔧 配置说明

服务器配置文件会自动生成，主要配置项：

- **端口**：默认 7777（可自定义）
- **最大玩家数**：默认 8 人
- **世界大小**：小/中/大
- **难度**：经典/专家/大师
- **PvP模式**：开启/关闭

## 📖 使用指南

1. **创建服务器**：点击"创建服务器"，填写服务器配置
2. **启动服务器**：首次启动会自动下载官方服务器文件（约45MB）
3. **监控状态**：实时查看服务器运行状态和资源使用情况
4. **管理玩家**：查看在线玩家，执行管理操作

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

- [Terraria](https://terraria.org/) - 官方游戏和服务器
- [Go](https://golang.org/) - 后端开发语言
- [Vue.js](https://vuejs.org/) - 前端框架
