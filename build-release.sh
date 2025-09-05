#!/bin/bash

###########################################
# 泰拉瑞亚管理面板 - 生产版本编译脚本
# Terraria Panel Production Build Script
# 老王暴躁技术流 出品
###########################################

set -e  # 遇到错误立即退出

# 颜色输出函数
function echo_red() {
    echo -e "\033[0;31m$*\033[0m"
}

function echo_green() {
    echo -e "\033[0;32m$*\033[0m"
}

function echo_yellow() {
    echo -e "\033[0;33m$*\033[0m"
}

function echo_cyan() {
    echo -e "\033[0;36m$*\033[0m"
}

function echo_blue() {
    echo -e "\033[0;34m$*\033[0m"
}

# 项目信息
PROJECT_NAME="terraria-panel"
VERSION=${1:-"v1.0.0"}
BUILD_TIME=$(date '+%Y-%m-%d %H:%M:%S')
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# 目录设置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GO_SOURCE_DIR="$PROJECT_ROOT/terraria-go"
FRONTEND_SOURCE_DIR="$PROJECT_ROOT/koi-ui"
BUILD_DIR="$SCRIPT_DIR/build"
RELEASE_DIR="$SCRIPT_DIR/release"

echo_blue "================================"
echo_blue "🎮 泰拉瑞亚管理面板编译脚本"
echo_blue "   Production Build Script"
echo_blue "   老王暴躁技术流 出品"
echo_blue "================================"
echo ""
echo_green "📋 编译信息:"
echo "  项目名称: $PROJECT_NAME"
echo "  版本号: $VERSION"
echo "  编译时间: $BUILD_TIME"
echo "  Git提交: $GIT_COMMIT"
echo "  Go源码目录: $GO_SOURCE_DIR"
echo "  前端源码目录: $FRONTEND_SOURCE_DIR"
echo ""

# 检查依赖
function check_dependencies() {
    echo_cyan "🔍 检查编译依赖..."
    
    # 检查Go
    if ! command -v go >/dev/null 2>&1; then
        echo_red "❌ Go未安装，请先安装Go 1.19+"
        exit 1
    fi
    
    local go_version=$(go version | grep -o 'go[0-9]\+\.[0-9]\+' | sed 's/go//')
    echo_green "✅ Go版本: $go_version"
    
    # 检查Node.js (可选)
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version)
        echo_green "✅ Node.js版本: $node_version"
    else
        echo_yellow "⚠ Node.js未安装，将跳过前端编译"
    fi
    
    # 检查Git
    if command -v git >/dev/null 2>&1; then
        echo_green "✅ Git可用"
    else
        echo_yellow "⚠ Git未安装，版本信息可能不准确"
    fi
}

# 清理构建目录
function clean_build() {
    echo_cyan "🧹 清理构建目录..."
    rm -rf "$BUILD_DIR" "$RELEASE_DIR"
    mkdir -p "$BUILD_DIR" "$RELEASE_DIR"
    echo_green "✅ 构建目录已清理"
}

# 编译前端 (如果存在)
function build_frontend() {
    if [ ! -d "$FRONTEND_SOURCE_DIR" ]; then
        echo_yellow "⚠ 前端源码目录不存在，跳过前端编译"
        return 0
    fi
    
    echo_cyan "🌐 编译前端代码..."
    cd "$FRONTEND_SOURCE_DIR"
    
    # 检查package.json
    if [ ! -f "package.json" ]; then
        echo_yellow "⚠ 未找到package.json，跳过前端编译"
        return 0
    fi
    
    # 安装依赖
    if [ ! -d "node_modules" ]; then
        echo_cyan "📦 安装前端依赖..."
        if command -v pnpm >/dev/null 2>&1; then
            pnpm install
        elif command -v yarn >/dev/null 2>&1; then
            yarn install
        else
            npm install
        fi
    fi
    
    # 构建前端
    echo_cyan "🔨 构建前端..."
    if command -v pnpm >/dev/null 2>&1; then
        pnpm build
    elif command -v yarn >/dev/null 2>&1; then
        yarn build
    else
        npm run build
    fi
    
    # 复制构建结果
    if [ -d "dist" ]; then
        cp -r dist "$BUILD_DIR/frontend"
        echo_green "✅ 前端编译完成"
    else
        echo_red "❌ 前端编译失败，未找到dist目录"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
}

# 编译Go后端
function build_backend() {
    echo_cyan "🔧 编译Go后端..."
    
    if [ ! -d "$GO_SOURCE_DIR" ]; then
        echo_red "❌ Go源码目录不存在: $GO_SOURCE_DIR"
        exit 1
    fi
    
    cd "$GO_SOURCE_DIR"
    
    # 检查go.mod
    if [ ! -f "go.mod" ]; then
        echo_red "❌ 未找到go.mod文件"
        exit 1
    fi
    
    # 下载依赖
    echo_cyan "📦 下载Go依赖..."
    go mod tidy
    go mod download
    
    # 编译参数
    local ldflags="-s -w -X 'main.version=$VERSION' -X 'main.buildTime=$BUILD_TIME' -X 'main.gitCommit=$GIT_COMMIT'"
    
    # 编译不同平台版本
    echo_cyan "🔨 编译多平台版本..."
    
    # Linux AMD64
    echo_cyan "  🐧 编译 Linux AMD64..."
    GOOS=linux GOARCH=amd64 go build -ldflags="$ldflags" -o "$BUILD_DIR/terraria-panel-linux" terraria-manager.go
    
    # Windows AMD64
    echo_cyan "  🪟 编译 Windows AMD64..."
    GOOS=windows GOARCH=amd64 go build -ldflags="$ldflags" -o "$BUILD_DIR/terraria-panel-windows.exe" terraria-manager.go
    
    # macOS AMD64
    echo_cyan "  🍎 编译 macOS AMD64..."
    GOOS=darwin GOARCH=amd64 go build -ldflags="$ldflags" -o "$BUILD_DIR/terraria-panel-macos" terraria-manager.go
    
    # Linux ARM64 (树莓派等)
    echo_cyan "  🔧 编译 Linux ARM64..."
    GOOS=linux GOARCH=arm64 go build -ldflags="$ldflags" -o "$BUILD_DIR/terraria-panel-linux-arm64" terraria-manager.go
    
    echo_green "✅ Go后端编译完成"
    cd "$SCRIPT_DIR"
}

# 创建发布包
function create_release_packages() {
    echo_cyan "📦 创建发布包..."
    
    cd "$BUILD_DIR"
    
    # 创建各平台发布包
    local platforms=("linux" "windows" "macos" "linux-arm64")
    
    for platform in "${platforms[@]}"; do
        echo_cyan "  📦 打包 $platform 版本..."
        
        local package_dir="terraria-panel-$platform"
        local executable=""
        
        case $platform in
            "windows")
                executable="terraria-panel-windows.exe"
                ;;
            "macos")
                executable="terraria-panel-macos"
                ;;
            "linux-arm64")
                executable="terraria-panel-linux-arm64"
                ;;
            *)
                executable="terraria-panel-linux"
                ;;
        esac
        
        # 创建包目录
        mkdir -p "$package_dir"
        
        # 复制可执行文件
        if [ -f "$executable" ]; then
            cp "$executable" "$package_dir/terraria-panel"
            chmod +x "$package_dir/terraria-panel"
        else
            echo_yellow "⚠ 跳过 $platform，可执行文件不存在"
            continue
        fi
        
        # 复制前端文件
        if [ -d "frontend" ]; then
            cp -r frontend "$package_dir/dist"
        fi
        
        # 创建启动脚本
        if [[ "$platform" == "windows" ]]; then
            cat > "$package_dir/start.bat" << 'EOF'
@echo off
chcp 65001 >nul
echo 🎮 启动泰拉瑞亚管理面板...
echo 📍 访问地址: http://localhost:8090
echo.
terraria-panel.exe
pause
EOF
        else
            cat > "$package_dir/start.sh" << 'EOF'
#!/bin/bash
echo "🎮 启动泰拉瑞亚管理面板..."
echo "📍 访问地址: http://localhost:8090"
echo ""
./terraria-panel
EOF
            chmod +x "$package_dir/start.sh"
        fi
        
        # 创建README
        cat > "$package_dir/README.md" << EOF
# 🎮 泰拉瑞亚服务器管理面板

版本: $VERSION
编译时间: $BUILD_TIME
平台: $platform

## 🚀 快速启动

### Linux/macOS:
\`\`\`bash
./start.sh
\`\`\`

### Windows:
\`\`\`cmd
start.bat
\`\`\`

## 🌐 访问地址

- 管理面板: http://localhost:8090
- API文档: http://localhost:8090/api/
- WebSocket: ws://localhost:8090/ws

## 📋 功能特性

- 🚀 一键启动泰拉瑞亚服务器
- 📊 实时监控服务器状态
- 👥 玩家管理
- 🌍 世界管理
- 📝 日志查看
- 🔄 自动下载官方服务器文件

## 🛠️ 技术支持

- GitHub: https://github.com/ShourGG/terraria-server-manager
- 老王暴躁技术流 出品
EOF
        
        # 打包
        if command -v zip >/dev/null 2>&1; then
            zip -r "$RELEASE_DIR/terraria-panel-$platform.zip" "$package_dir"
        else
            tar -czf "$RELEASE_DIR/terraria-panel-$platform.tar.gz" "$package_dir"
        fi
        
        echo_green "  ✅ $platform 版本打包完成"
    done
    
    cd "$SCRIPT_DIR"
}

# 生成部署脚本
function generate_deploy_script() {
    echo_cyan "📝 生成Linux一键部署脚本..."
    
    cat > "$RELEASE_DIR/deploy-production.sh" << 'EOF'
#!/bin/bash

###########################################
# 泰拉瑞亚管理面板 - Linux生产环境一键部署脚本
# Terraria Panel Linux Production Deploy
# 老王暴躁技术流 出品
###########################################

set -e

# 配置参数
GITHUB_REPO="ShourGG/terraria-server-manager"
INSTALL_DIR="$HOME/terraria-panel"
SERVICE_PORT="8090"

# 颜色输出
function echo_red() { echo -e "\033[0;31m$*\033[0m"; }
function echo_green() { echo -e "\033[0;32m$*\033[0m"; }
function echo_yellow() { echo -e "\033[0;33m$*\033[0m"; }
function echo_cyan() { echo -e "\033[0;36m$*\033[0m"; }
function echo_blue() { echo -e "\033[0;34m$*\033[0m"; }

echo_blue "================================"
echo_blue "🎮 泰拉瑞亚管理面板"
echo_blue "   Linux生产环境一键部署"
echo_blue "   老王暴躁技术流 出品"
echo_blue "================================"

# 检测系统架构
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        PLATFORM="linux"
        ;;
    aarch64|arm64)
        PLATFORM="linux-arm64"
        ;;
    *)
        echo_red "❌ 不支持的系统架构: $ARCH"
        exit 1
        ;;
esac

echo_green "📋 系统信息:"
echo "  操作系统: $(uname -s)"
echo "  架构: $ARCH"
echo "  平台: $PLATFORM"
echo "  安装目录: $INSTALL_DIR"
echo ""

# 下载最新版本
function download_latest() {
    echo_cyan "📥 下载最新版本..."
    
    # 获取最新版本信息
    local latest_url="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
    local download_url
    
    if command -v curl >/dev/null 2>&1; then
        download_url=$(curl -s "$latest_url" | grep "browser_download_url.*$PLATFORM" | cut -d '"' -f 4 | head -1)
    elif command -v wget >/dev/null 2>&1; then
        download_url=$(wget -qO- "$latest_url" | grep "browser_download_url.*$PLATFORM" | cut -d '"' -f 4 | head -1)
    else
        echo_red "❌ 需要安装 curl 或 wget"
        exit 1
    fi
    
    if [ -z "$download_url" ]; then
        echo_red "❌ 未找到适合的下载链接"
        exit 1
    fi
    
    echo_green "📦 下载地址: $download_url"
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # 下载文件
    local filename=$(basename "$download_url")
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$filename" "$download_url"
    else
        wget -O "$filename" "$download_url"
    fi
    
    # 解压文件
    if [[ "$filename" == *.zip ]]; then
        unzip -q "$filename"
    else
        tar -xzf "$filename"
    fi
    
    # 查找解压后的目录
    local extracted_dir=$(find . -maxdepth 1 -type d -name "terraria-panel-*" | head -1)
    if [ -z "$extracted_dir" ]; then
        echo_red "❌ 解压失败"
        exit 1
    fi
    
    # 安装文件
    echo_cyan "📁 安装文件到 $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"
    mkdir -p "$(dirname "$INSTALL_DIR")"
    mv "$extracted_dir" "$INSTALL_DIR"
    
    # 设置权限
    chmod +x "$INSTALL_DIR/terraria-panel"
    if [ -f "$INSTALL_DIR/start.sh" ]; then
        chmod +x "$INSTALL_DIR/start.sh"
    fi
    
    # 清理临时文件
    cd "$HOME"
    rm -rf "$temp_dir"
    
    echo_green "✅ 安装完成"
}

# 启动服务
function start_service() {
    echo_cyan "🚀 启动服务..."
    
    cd "$INSTALL_DIR"
    
    # 停止可能存在的旧进程
    pkill -f "terraria-panel" 2>/dev/null || true
    
    # 启动服务
    nohup ./terraria-panel > terraria-panel.log 2>&1 &
    local pid=$!
    echo $pid > terraria-panel.pid
    
    # 等待启动
    sleep 3
    
    # 检查服务状态
    if kill -0 $pid 2>/dev/null; then
        echo_green "✅ 服务启动成功 (PID: $pid)"
        
        # 检查端口
        if netstat -tuln 2>/dev/null | grep -q ":$SERVICE_PORT " || ss -tuln 2>/dev/null | grep -q ":$SERVICE_PORT "; then
            echo_green "✅ 端口 $SERVICE_PORT 监听正常"
        else
            echo_yellow "⚠ 端口监听检查失败，但进程正在运行"
        fi
    else
        echo_red "❌ 服务启动失败"
        exit 1
    fi
}

# 显示完成信息
function show_completion() {
    echo ""
    echo_blue "================================"
    echo_blue "🎉 部署完成！"
    echo_blue "================================"
    echo ""
    echo_green "📁 安装目录: $INSTALL_DIR"
    echo_green "🌐 访问地址: http://YOUR_SERVER_IP:$SERVICE_PORT"
    echo_green "🏠 本地访问: http://localhost:$SERVICE_PORT"
    echo ""
    echo_green "🔧 管理命令:"
    echo "  查看状态: ps aux | grep terraria-panel"
    echo "  停止服务: pkill -f terraria-panel"
    echo "  查看日志: tail -f $INSTALL_DIR/terraria-panel.log"
    echo "  重新启动: cd $INSTALL_DIR && nohup ./terraria-panel > terraria-panel.log 2>&1 &"
    echo ""
    echo_green "💡 提示:"
    echo "  - 确保防火墙开放端口 $SERVICE_PORT"
    echo "  - 首次使用请在面板中创建泰拉瑞亚服务器"
    echo "  - 服务器文件将自动从官方下载"
    echo ""
}

# 主函数
function main() {
    download_latest
    start_service
    show_completion
}

# 运行主函数
main "$@"
EOF
    
    chmod +x "$RELEASE_DIR/deploy-production.sh"
    echo_green "✅ Linux部署脚本生成完成"
}

# 显示构建结果
function show_build_results() {
    echo ""
    echo_blue "================================"
    echo_blue "🎉 编译完成！"
    echo_blue "================================"
    echo ""
    echo_green "📁 构建目录: $BUILD_DIR"
    echo_green "📦 发布目录: $RELEASE_DIR"
    echo ""
    echo_green "📋 发布文件:"
    if [ -d "$RELEASE_DIR" ]; then
        ls -la "$RELEASE_DIR"
    fi
    echo ""
    echo_green "🚀 下一步操作:"
    echo "  1. 上传发布文件到GitHub Release"
    echo "  2. 在Linux服务器运行: curl -sSL https://raw.githubusercontent.com/$GITHUB_REPO/main/deploy-production.sh | bash"
    echo "  3. 或者手动下载对应平台的压缩包解压使用"
    echo ""
}

# 主函数
function main() {
    check_dependencies
    clean_build
    build_frontend
    build_backend
    create_release_packages
    generate_deploy_script
    show_build_results
}

# 运行主函数
main "$@"
