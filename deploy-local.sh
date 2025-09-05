#!/bin/bash

# 🎮 泰拉瑞亚服务器管理面板 - 本地部署脚本
# 作者：老王暴躁技术流
# 功能：本地文件部署，不依赖GitHub下载，真正可用的部署方案

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
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
    echo -e "${BLUE}   本地部署脚本 v2.0${NC}"
    echo -e "${BLUE}   (不依赖GitHub下载)${NC}"
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

# 本地部署
local_deploy() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local source_dir=""
    local zip_file=""

    print_message "从本地文件部署..."

    # 查找ZIP文件进行部署
    if [ -f "$script_dir/terraria-panel-$PLATFORM.zip" ]; then
        zip_file="$script_dir/terraria-panel-$PLATFORM.zip"
    elif [ -f "$script_dir/terraria-panel-linux.zip" ]; then
        zip_file="$script_dir/terraria-panel-linux.zip"
    fi

    if [ -n "$zip_file" ]; then
        print_message "找到ZIP文件: $zip_file"

        # 创建安装目录
        mkdir -p "$INSTALL_DIR"

        # 解压ZIP文件
        if command -v unzip >/dev/null 2>&1; then
            print_message "解压文件到: $INSTALL_DIR"
            unzip -q "$zip_file" -d "$INSTALL_DIR"
            print_message "✅ ZIP文件解压完成"
        else
            print_error "系统缺少unzip命令，请安装: apt-get install unzip 或 yum install unzip"
            exit 1
        fi
    else
        # 回退到目录复制方式
        if [ -d "$script_dir/temp-$PLATFORM" ]; then
            source_dir="$script_dir/temp-$PLATFORM"
        elif [ -d "$script_dir/temp-linux" ]; then
            source_dir="$script_dir/temp-linux"
        else
            print_error "找不到部署文件"
            print_error "请确保以下文件或目录之一存在："
            print_error "  - terraria-panel-$PLATFORM.zip"
            print_error "  - terraria-panel-linux.zip"
            print_error "  - temp-$PLATFORM/"
            print_error "  - temp-linux/"
            print_error ""
            print_error "当前目录内容："
            ls -la "$script_dir" 2>/dev/null || true
            exit 1
        fi

        print_message "找到源文件目录: $source_dir"

        # 创建安装目录
        mkdir -p "$INSTALL_DIR"

        # 复制文件
        print_message "复制文件到: $INSTALL_DIR"
        cp -r "$source_dir"/* "$INSTALL_DIR/"

        # 复制前端文件
        if [ -d "$script_dir/dist" ]; then
            cp -r "$script_dir/dist" "$INSTALL_DIR/"
            print_message "✅ 复制前端文件"
        fi
    fi

    # 设置执行权限
    chmod +x "$INSTALL_DIR/terraria-panel"* 2>/dev/null || true
    if [ -f "$INSTALL_DIR/start.sh" ]; then
        chmod +x "$INSTALL_DIR/start.sh"
    fi

    print_message "本地部署完成！"
}

# 启动服务
start_service() {
    print_message "启动服务..."
    cd "$INSTALL_DIR"

    # 停止可能存在的旧进程
    pkill -f "terraria-panel" 2>/dev/null || true
    pkill -f "python3 -m http.server 8090" 2>/dev/null || true

    # 查找可执行文件
    local executable=""
    if [ -f "./terraria-panel" ]; then
        executable="./terraria-panel"
    elif [ -f "./terraria-panel-linux" ]; then
        executable="./terraria-panel-linux"
    elif [ -f "./terraria-panel-linux-new" ]; then
        executable="./terraria-panel-linux-new"
    else
        print_error "找不到 terraria-panel 程序文件"
        print_error "当前目录内容："
        ls -la . 2>/dev/null || true
        print_warning "尝试使用Python HTTP服务器作为备选方案"

        # 使用Python HTTP服务器作为备选
        if command -v python3 >/dev/null 2>&1; then
            nohup python3 -m http.server 8090 --bind 0.0.0.0 > web-server.log 2>&1 &
            echo $! > web-server.pid
            print_message "✅ 使用Python HTTP服务器启动"
            sleep 3
            check_port_listening
            return
        else
            print_error "Python3也不可用，部署失败"
            exit 1
        fi
    fi

    print_message "找到可执行文件: $executable"

    # 启动服务
    if $executable > terraria-panel.log 2>&1 &
    then
        echo $! > terraria-panel.pid
        print_message "✅ 使用 $executable 启动成功"
    else
        print_warning "$executable 启动失败，使用Python HTTP服务器"
        if command -v python3 >/dev/null 2>&1; then
            nohup python3 -m http.server 8090 --bind 0.0.0.0 > web-server.log 2>&1 &
            echo $! > web-server.pid
            print_message "✅ 使用Python HTTP服务器启动"
        else
            print_error "启动失败，无可用的服务器程序"
            exit 1
        fi
    fi

    sleep 3
    check_port_listening
}

# 检查端口监听
check_port_listening() {
    if command -v netstat >/dev/null 2>&1; then
        if netstat -tlnp 2>/dev/null | grep -q ":8090"; then
            print_message "✅ 端口8090监听正常"
        else
            print_warning "⚠️ 端口8090未监听，可能启动失败"
        fi
    elif command -v ss >/dev/null 2>&1; then
        if ss -tlnp 2>/dev/null | grep -q ":8090"; then
            print_message "✅ 端口8090监听正常"
        else
            print_warning "⚠️ 端口8090未监听，可能启动失败"
        fi
    fi
}

# 显示完成信息
show_completion() {
    echo ""
    print_title
    print_message "🎉 部署完成！"
    echo ""
    print_message "📁 安装目录: $INSTALL_DIR"
    
    # 获取公网IP
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "获取失败")
    if [ "$PUBLIC_IP" != "获取失败" ]; then
        print_message "🌐 公网访问: http://$PUBLIC_IP:8090"
    fi
    print_message "🏠 本地访问: http://localhost:8090"
    echo ""
    print_message "🔧 管理命令:"
    echo "  查看状态: ps aux | grep -E '(terraria-panel|python3.*8090)'"
    echo "  停止服务: pkill -f 'terraria-panel|python3.*8090'"
    echo "  查看日志: tail -f $INSTALL_DIR/terraria-panel.log"
    echo "  重新启动: cd $INSTALL_DIR && bash $(basename $0)"
    echo ""
    print_message "💡 提示："
    echo "  - 确保云服务器安全组开放8090端口"
    echo "  - 如果无法访问，检查防火墙设置"
    echo "  - 程序日志位于: $INSTALL_DIR/terraria-panel.log"
    echo ""
}

# 主函数
main() {
    print_title
    
    print_message "🚀 开始本地部署..."
    print_message "📍 当前工作目录: $(pwd)"
    print_message "📂 脚本所在目录: $(dirname "${BASH_SOURCE[0]}")"
    
    # 执行部署步骤
    detect_platform
    local_deploy
    start_service
    show_completion
}

# 运行主函数
main "$@"
