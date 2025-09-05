#!/bin/bash

# 🎮 泰拉瑞亚服务器管理面板 - 一键部署脚本
# 作者：老王暴躁技术流
# 功能：自动下载并部署面板

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
GITHUB_REPO="your-username/terraria-panel"
GITHUB_API="https://api.github.com/repos/$GITHUB_REPO"
INSTALL_DIR="$HOME/terraria-panel"
SERVICE_NAME="terraria-panel"

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_title() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}🎮 泰拉瑞亚服务器管理面板${NC}"
    echo -e "${BLUE}   一键部署脚本 v1.0${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# 检测系统架构
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case $os in
        linux*)
            PLATFORM="linux"
            ;;
        darwin*)
            PLATFORM="macos"
            ;;
        *)
            print_error "不支持的操作系统: $os"
            exit 1
            ;;
    esac
    
    case $arch in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        *)
            print_error "不支持的架构: $arch"
            exit 1
            ;;
    esac
    
    print_message "检测到系统: $PLATFORM-$ARCH"
}

# 获取最新版本
get_latest_version() {
    print_message "获取最新版本信息..."
    
    if command -v curl >/dev/null 2>&1; then
        LATEST_VERSION=$(curl -s "$GITHUB_API/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    elif command -v wget >/dev/null 2>&1; then
        LATEST_VERSION=$(wget -qO- "$GITHUB_API/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        print_error "需要安装 curl 或 wget"
        exit 1
    fi
    
    if [ -z "$LATEST_VERSION" ]; then
        print_error "无法获取最新版本信息"
        exit 1
    fi
    
    print_message "最新版本: $LATEST_VERSION"
}

# 下载文件
download_release() {
    local filename="terraria-panel-$PLATFORM.tar.gz"
    local download_url="https://github.com/$GITHUB_REPO/releases/download/$LATEST_VERSION/$filename"
    
    print_message "下载发布包: $filename"
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$filename" "$download_url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$filename" "$download_url"
    else
        print_error "需要安装 curl 或 wget"
        exit 1
    fi
    
    if [ ! -f "$filename" ]; then
        print_error "下载失败"
        exit 1
    fi
    
    print_message "解压文件..."
    tar -xzf "$filename"
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    
    # 复制文件
    print_message "安装到: $INSTALL_DIR"
    cp -r terraria-panel-$PLATFORM/* "$INSTALL_DIR/"
    
    # 设置执行权限
    chmod +x "$INSTALL_DIR/terraria-panel"
    if [ -f "$INSTALL_DIR/start.sh" ]; then
        chmod +x "$INSTALL_DIR/start.sh"
    fi
    
    # 清理临时文件
    cd "$HOME"
    rm -rf "$temp_dir"
    
    print_message "安装完成！"
}

# 创建系统服务
create_service() {
    if [ "$EUID" -eq 0 ]; then
        print_message "创建系统服务..."
        
        cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=Terraria Server Management Panel
After=network.target

[Service]
Type=simple
User=$SUDO_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/terraria-panel
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        systemctl enable "$SERVICE_NAME"
        
        print_message "系统服务已创建"
    else
        print_warning "非root用户，跳过系统服务创建"
    fi
}

# 启动服务
start_service() {
    if [ "$EUID" -eq 0 ] && systemctl is-enabled "$SERVICE_NAME" >/dev/null 2>&1; then
        print_message "启动系统服务..."
        systemctl start "$SERVICE_NAME"
        systemctl status "$SERVICE_NAME" --no-pager
    else
        print_message "手动启动服务..."
        cd "$INSTALL_DIR"
        nohup ./terraria-panel > terraria-panel.log 2>&1 &
        echo $! > terraria-panel.pid
        print_message "服务已在后台启动"
        print_message "日志文件: $INSTALL_DIR/terraria-panel.log"
        print_message "PID文件: $INSTALL_DIR/terraria-panel.pid"
    fi
}

# 显示完成信息
show_completion() {
    echo ""
    print_title
    print_message "🎉 部署完成！"
    echo ""
    print_message "📁 安装目录: $INSTALL_DIR"
    print_message "🌐 访问地址: http://localhost:8090"
    print_message "📚 使用文档: https://github.com/$GITHUB_REPO"
    echo ""
    print_message "🔧 管理命令:"
    if [ "$EUID" -eq 0 ] && systemctl is-enabled "$SERVICE_NAME" >/dev/null 2>&1; then
        echo "  启动服务: sudo systemctl start $SERVICE_NAME"
        echo "  停止服务: sudo systemctl stop $SERVICE_NAME"
        echo "  重启服务: sudo systemctl restart $SERVICE_NAME"
        echo "  查看状态: sudo systemctl status $SERVICE_NAME"
        echo "  查看日志: sudo journalctl -u $SERVICE_NAME -f"
    else
        echo "  启动服务: cd $INSTALL_DIR && ./start.sh"
        echo "  停止服务: kill \$(cat $INSTALL_DIR/terraria-panel.pid)"
        echo "  查看日志: tail -f $INSTALL_DIR/terraria-panel.log"
    fi
    echo ""
}

# 主函数
main() {
    print_title
    
    # 检查权限
    if [ "$EUID" -eq 0 ]; then
        print_message "以root用户运行，将创建系统服务"
    else
        print_message "以普通用户运行，将手动启动服务"
    fi
    
    # 执行部署步骤
    detect_platform
    get_latest_version
    download_release
    create_service
    start_service
    show_completion
}

# 运行主函数
main "$@"
