#!/bin/bash

###########################################
# 泰拉瑞亚管理面板 - 增强版自动化部署脚本
# Enhanced Terraria Panel Deployment Script
# 老王暴躁技术流 出品 - 基于DST管理平台脚本改进
###########################################

# --------------- ↓可修改↓ --------------- #
# 面板暴露端口，即网页打开时所用的端口
PORT=8090

# 数据库文件所在目录，例如：./config
CONFIG_DIR="./"

# 虚拟内存大小，例如 1G 4G等
SWAPSIZE=2G

# GitHub仓库信息
GITHUB_REPO="ShourGG/terraria-server-manager"
GITHUB_BRANCH="main"

# 本地文件目录
LOCAL_FILES_DIR="temp-linux"
# --------------- ↑可修改↑ --------------- #

###########################################
#     下方变量请不要修改，否则可能会出现异常     #
###########################################

USER=$(whoami)
PANEL_DIR="$HOME/terraria-panel"
PANEL_EXECUTABLE="$PANEL_DIR/terraria-panel"
LOG_FILE="$PANEL_DIR/terraria-panel.log"

cd "$HOME" || exit

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

# 检查用户权限（可选root检查，根据需要调整）
function check_user() {
    if [[ "${USER}" == "root" ]]; then
        echo_yellow "检测到root用户，建议使用普通用户运行以提高安全性"
        echo_yellow "是否继续？(y/N): "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo_red "用户取消操作"
            exit 1
        fi
    fi
}

# 设置全局stderr为红色并添加固定格式
function set_tty() {
    exec 2> >(while read -r line; do echo_red "[$(date +'%F %T')] [ERROR] ${line}" >&2; done)
}

# 恢复stderr颜色
function unset_tty() {
    exec 2> /dev/tty
}

# 显示主菜单
function show_menu() {
    clear
    echo_blue "🎮 泰拉瑞亚管理面板 - 增强版部署脚本"
    echo_blue "--- Enhanced Terraria Panel Deployment Script ---"
    echo_blue "--- 老王暴躁技术流 出品 (Based on DST Management Platform) ---"
    echo_yellow "————————————————————————————————————————————————————————————"
    echo_green "[0]: 智能部署服务 (Smart Deploy - Local First)"
    echo_green "[1]: GitHub部署 (Deploy from GitHub Release)"
    echo_green "[2]: 本地部署 (Deploy from Local Files)"
    echo_yellow "————————————————————————————————————————————————————————————"
    echo_green "[3]: 启动服务 (Start Service)"
    echo_green "[4]: 停止服务 (Stop Service)"
    echo_green "[5]: 重启服务 (Restart Service)"
    echo_green "[6]: 查看状态 (Check Status)"
    echo_yellow "————————————————————————————————————————————————————————————"
    echo_green "[7]: 更新面板 (Update Panel)"
    echo_green "[8]: 强制重装 (Force Reinstall)"
    echo_green "[9]: 清理文件 (Clean Files)"
    echo_yellow "————————————————————————————————————————————————————————————"
    echo_green "[10]: 设置虚拟内存 (Setup Swap)"
    echo_green "[11]: 查看日志 (View Logs)"
    echo_green "[12]: 退出脚本 (Exit)"
    echo_yellow "————————————————————————————————————————————————————————————"
    echo_yellow "请输入选择 (Please enter your selection) [0-12]: "
}

# 检查必要的命令
function check_dependencies() {
    echo_cyan "正在检查系统依赖 (Checking system dependencies)"
    
    local missing_deps=()
    
    # 检查curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    # 检查wget（备用）
    if ! command -v wget >/dev/null 2>&1; then
        missing_deps+=("wget")
    fi
    
    # 检查python3（备用方案）
    if ! command -v python3 >/dev/null 2>&1; then
        echo_yellow "警告：未检测到python3，备用HTTP服务器方案将不可用"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo_red "缺少必要依赖: ${missing_deps[*]}"
        echo_yellow "正在尝试自动安装..."
        
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y "${missing_deps[@]}"
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y "${missing_deps[@]}"
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y "${missing_deps[@]}"
        else
            echo_red "无法自动安装依赖，请手动安装: ${missing_deps[*]}"
            exit 1
        fi
    fi
    
    echo_green "依赖检查完成 ✓"
}

# 创建目录结构
function create_directories() {
    echo_cyan "创建目录结构 (Creating directory structure)"
    mkdir -p "$PANEL_DIR"
    cd "$PANEL_DIR" || {
        echo_red "无法进入目录: $PANEL_DIR"
        exit 1
    }
    echo_green "目录创建完成: $PANEL_DIR ✓"
}

# 下载函数：支持curl和wget
function download_file() {
    local url="$1"
    local output="$2"
    local timeout="${3:-30}"
    
    echo_cyan "正在下载: $url"
    
    if command -v curl >/dev/null 2>&1; then
        curl -L --connect-timeout "$timeout" --max-time $((timeout * 2)) \
             --progress-bar -o "$output" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget --timeout="$timeout" --progress=bar:force \
             -O "$output" "$url"
    else
        echo_red "错误：未找到curl或wget命令"
        return 1
    fi
    
    return $?
}

# 检查端口是否被占用
function check_port() {
    local port="$1"
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        return 0  # 端口被占用
    elif ss -tuln 2>/dev/null | grep -q ":$port "; then
        return 0  # 端口被占用
    else
        return 1  # 端口未被占用
    fi
}

# 检查服务状态
function check_service_status() {
    echo_cyan "检查服务状态 (Checking service status)"

    # 检查进程
    if pgrep -f "terraria-panel\|terraria-manager" >/dev/null; then
        echo_green "✓ 进程运行中 (Process running)"

        # 检查端口
        if check_port "$PORT"; then
            echo_green "✓ 端口 $PORT 正在监听 (Port $PORT listening)"

            # 检查HTTP响应
            if curl -s -I "http://localhost:$PORT" >/dev/null 2>&1; then
                echo_green "✓ HTTP服务响应正常 (HTTP service responding)"
                echo_green "🎉 服务运行正常！访问地址: http://YOUR_IP:$PORT"
                return 0
            else
                echo_yellow "⚠ HTTP服务无响应，可能正在启动中"
                return 1
            fi
        else
            echo_red "✗ 端口 $PORT 未监听 (Port $PORT not listening)"
            return 1
        fi
    else
        echo_red "✗ 进程未运行 (Process not running)"
        return 1
    fi
}

# 智能部署：优先本地，失败时使用GitHub
function smart_deploy() {
    echo_cyan "🧠 智能部署模式 (Smart Deploy Mode)"
    echo_yellow "策略：本地优先 -> GitHub备选 -> Python HTTP服务器"

    # 尝试本地部署
    if local_deploy; then
        echo_green "✅ 本地部署成功"
        return 0
    else
        echo_yellow "⚠ 本地部署失败，尝试GitHub部署..."
        if github_deploy; then
            echo_green "✅ GitHub部署成功"
            return 0
        else
            echo_yellow "⚠ GitHub部署失败，使用Python HTTP服务器..."
            return python_fallback_deploy
        fi
    fi
}

# 本地部署
function local_deploy() {
    echo_cyan "📁 本地部署模式 (Local Deploy Mode)"

    # 检查本地文件
    local source_dir=""
    local executable=""

    # 优先查找编译好的可执行文件
    if [ -f "../terraria-go/terraria-manager.exe" ]; then
        source_dir="../terraria-go"
        executable="terraria-manager.exe"
        echo_green "找到完整版管理器: $source_dir/$executable"
    elif [ -f "../terraria-go/minimal.exe" ]; then
        source_dir="../terraria-go"
        executable="minimal.exe"
        echo_green "找到简化版管理器: $source_dir/$executable"
    elif [ -f "temp-linux/terraria-panel" ]; then
        source_dir="temp-linux"
        executable="terraria-panel"
        echo_green "找到Linux版本: $source_dir/$executable"
    elif [ -f "release/terraria-panel-linux" ]; then
        source_dir="release"
        executable="terraria-panel-linux"
        echo_green "找到发布版本: $source_dir/$executable"
    else
        echo_red "❌ 未找到可执行文件"
        return 1
    fi

    create_directories

    # 复制可执行文件
    echo_cyan "复制可执行文件..."
    cp "$source_dir/$executable" "$PANEL_DIR/terraria-panel"
    chmod +x "$PANEL_DIR/terraria-panel"

    # 复制前端文件
    if [ -d "dist" ]; then
        echo_cyan "复制前端文件..."
        cp -r dist/* "$PANEL_DIR/"
        echo_green "✅ 前端文件复制完成"
    elif [ -d "temp-linux/dist" ]; then
        cp -r temp-linux/dist/* "$PANEL_DIR/"
        echo_green "✅ 前端文件复制完成"
    else
        echo_yellow "⚠ 未找到前端文件，将使用内置页面"
    fi

    return 0
}

# GitHub部署
function github_deploy() {
    echo_cyan "🌐 GitHub部署模式 (GitHub Deploy Mode)"

    check_dependencies
    create_directories

    # 获取最新版本信息
    echo_cyan "获取最新版本信息..."
    local latest_url="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
    local release_info

    if command -v curl >/dev/null 2>&1; then
        release_info=$(curl -s "$latest_url")
    else
        echo_red "❌ 需要curl命令进行GitHub下载"
        return 1
    fi

    if [ -z "$release_info" ]; then
        echo_red "❌ 无法获取GitHub Release信息"
        return 1
    fi

    # 解析下载链接（这里需要根据实际的Release结构调整）
    local download_url
    if command -v jq >/dev/null 2>&1; then
        download_url=$(echo "$release_info" | jq -r '.assets[] | select(.name | contains("linux")) | .browser_download_url' | head -1)
    else
        # 简单的grep解析（不够健壮，但作为备选）
        download_url=$(echo "$release_info" | grep -o 'https://[^"]*linux[^"]*' | head -1)
    fi

    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
        echo_red "❌ 未找到Linux版本下载链接"
        return 1
    fi

    # 下载文件
    local temp_file="$PANEL_DIR/terraria-panel-download.zip"
    echo_cyan "下载文件: $download_url"

    if download_file "$download_url" "$temp_file" 60; then
        echo_green "✅ 下载完成"

        # 解压文件
        if command -v unzip >/dev/null 2>&1; then
            cd "$PANEL_DIR"
            unzip -q "$temp_file"
            rm -f "$temp_file"

            # 查找可执行文件并设置权限
            find . -name "terraria-panel*" -type f -exec chmod +x {} \;

            echo_green "✅ GitHub部署完成"
            return 0
        else
            echo_red "❌ 需要unzip命令解压文件"
            return 1
        fi
    else
        echo_red "❌ 下载失败"
        return 1
    fi
}

# Python HTTP服务器备选方案
function python_fallback_deploy() {
    echo_cyan "🐍 Python HTTP服务器备选方案"

    if ! command -v python3 >/dev/null 2>&1; then
        echo_red "❌ 未找到python3，无法启动备选服务器"
        return 1
    fi

    create_directories

    # 复制前端文件
    if [ -d "dist" ]; then
        cp -r dist/* "$PANEL_DIR/"
    elif [ -d "temp-linux/dist" ]; then
        cp -r temp-linux/dist/* "$PANEL_DIR/"
    else
        # 创建简单的HTML页面
        cat > "$PANEL_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>泰拉瑞亚管理面板</title>
    <meta charset="utf-8">
</head>
<body>
    <h1>🎮 泰拉瑞亚管理面板</h1>
    <p>Python HTTP服务器模式</p>
    <p>请手动部署真正的管理面板程序</p>
</body>
</html>
EOF
    fi

    echo_green "✅ Python备选方案准备完成"
    return 0
}

# 启动服务
function start_service() {
    echo_cyan "🚀 启动服务 (Starting Service)"

    # 停止可能存在的旧进程
    stop_service_quiet

    cd "$PANEL_DIR" || {
        echo_red "❌ 无法进入目录: $PANEL_DIR"
        return 1
    }

    # 检查可执行文件
    if [ -f "./terraria-panel" ]; then
        echo_cyan "使用泰拉瑞亚管理面板程序启动..."

        # 启动程序
        nohup ./terraria-panel > "$LOG_FILE" 2>&1 &
        local pid=$!
        echo $pid > terraria-panel.pid

        # 等待启动
        sleep 3

        # 检查进程是否还在运行
        if kill -0 $pid 2>/dev/null; then
            echo_green "✅ 泰拉瑞亚管理面板启动成功 (PID: $pid)"

            # 等待端口监听
            local count=0
            while [ $count -lt 10 ]; do
                if check_port "$PORT"; then
                    echo_green "✅ 端口 $PORT 监听成功"
                    return 0
                fi
                sleep 1
                count=$((count + 1))
            done

            echo_yellow "⚠ 端口监听超时，但进程正在运行"
            return 0
        else
            echo_red "❌ 程序启动失败，尝试Python备选方案..."
            start_python_server
        fi
    else
        echo_yellow "⚠ 未找到terraria-panel程序，使用Python服务器..."
        start_python_server
    fi
}

# 启动Python HTTP服务器
function start_python_server() {
    echo_cyan "🐍 启动Python HTTP服务器..."

    if ! command -v python3 >/dev/null 2>&1; then
        echo_red "❌ 未找到python3命令"
        return 1
    fi

    cd "$PANEL_DIR" || return 1

    # 启动Python HTTP服务器
    nohup python3 -m http.server "$PORT" --bind 0.0.0.0 > python-server.log 2>&1 &
    local pid=$!
    echo $pid > python-server.pid

    sleep 2

    if kill -0 $pid 2>/dev/null; then
        echo_green "✅ Python HTTP服务器启动成功 (PID: $pid)"
        return 0
    else
        echo_red "❌ Python HTTP服务器启动失败"
        return 1
    fi
}

# 静默停止服务
function stop_service_quiet() {
    pkill -f "terraria-panel\|terraria-manager" 2>/dev/null || true
    pkill -f "python3.*$PORT" 2>/dev/null || true
    sleep 1
}

# 停止服务
function stop_service() {
    echo_cyan "🛑 停止服务 (Stopping Service)"

    local stopped=false

    # 停止泰拉瑞亚面板
    if [ -f "$PANEL_DIR/terraria-panel.pid" ]; then
        local pid=$(cat "$PANEL_DIR/terraria-panel.pid")
        if kill -0 $pid 2>/dev/null; then
            echo_cyan "停止泰拉瑞亚面板进程 (PID: $pid)..."
            kill $pid
            sleep 2
            if kill -0 $pid 2>/dev/null; then
                kill -9 $pid 2>/dev/null
            fi
            echo_green "✅ 泰拉瑞亚面板已停止"
            stopped=true
        fi
        rm -f "$PANEL_DIR/terraria-panel.pid"
    fi

    # 停止Python服务器
    if [ -f "$PANEL_DIR/python-server.pid" ]; then
        local pid=$(cat "$PANEL_DIR/python-server.pid")
        if kill -0 $pid 2>/dev/null; then
            echo_cyan "停止Python服务器进程 (PID: $pid)..."
            kill $pid
            sleep 1
            if kill -0 $pid 2>/dev/null; then
                kill -9 $pid 2>/dev/null
            fi
            echo_green "✅ Python服务器已停止"
            stopped=true
        fi
        rm -f "$PANEL_DIR/python-server.pid"
    fi

    # 通用进程清理
    if pgrep -f "terraria-panel\|terraria-manager" >/dev/null; then
        pkill -f "terraria-panel\|terraria-manager"
        echo_green "✅ 清理残留进程"
        stopped=true
    fi

    if pgrep -f "python3.*$PORT" >/dev/null; then
        pkill -f "python3.*$PORT"
        echo_green "✅ 清理Python服务器进程"
        stopped=true
    fi

    if [ "$stopped" = true ]; then
        echo_green "🎉 所有服务已停止"
    else
        echo_yellow "⚠ 未发现运行中的服务"
    fi
}

# 重启服务
function restart_service() {
    echo_cyan "🔄 重启服务 (Restarting Service)"
    stop_service
    sleep 2
    start_service
}

# 查看日志
function view_logs() {
    echo_cyan "📋 查看日志 (View Logs)"

    if [ -f "$LOG_FILE" ]; then
        echo_green "=== 泰拉瑞亚面板日志 ==="
        tail -n 50 "$LOG_FILE"
    fi

    if [ -f "$PANEL_DIR/python-server.log" ]; then
        echo_green "=== Python服务器日志 ==="
        tail -n 20 "$PANEL_DIR/python-server.log"
    fi

    if [ ! -f "$LOG_FILE" ] && [ ! -f "$PANEL_DIR/python-server.log" ]; then
        echo_yellow "⚠ 未找到日志文件"
    fi
}

# 清理文件
function clean_files() {
    echo_cyan "🧹 清理文件 (Clean Files)"

    echo_yellow "警告：此操作将删除所有安装文件和日志"
    echo_yellow "是否继续？(y/N): "
    read -r confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        stop_service

        if [ -d "$PANEL_DIR" ]; then
            rm -rf "$PANEL_DIR"
            echo_green "✅ 安装目录已删除: $PANEL_DIR"
        fi

        echo_green "🎉 清理完成"
    else
        echo_yellow "⚠ 用户取消操作"
    fi
}

# 设置虚拟内存
function setup_swap() {
    echo_cyan "💾 设置虚拟内存 (Setup Swap)"

    # 检查是否为root用户
    if [ "$EUID" -ne 0 ]; then
        echo_red "❌ 设置虚拟内存需要root权限"
        echo_yellow "请使用: sudo $0"
        return 1
    fi

    local swapfile="/swapfile"

    # 检查是否已经存在交换文件
    if [ -f "$swapfile" ]; then
        echo_green "✅ 交换文件已存在，跳过创建步骤"
    else
        echo_cyan "创建交换文件 ($SWAPSIZE)..."

        # 创建交换文件
        if command -v fallocate >/dev/null 2>&1; then
            fallocate -l "$SWAPSIZE" "$swapfile"
        else
            dd if=/dev/zero of="$swapfile" bs=1M count=$(echo "$SWAPSIZE" | sed 's/G/*1024/g' | sed 's/M//g' | bc) 2>/dev/null
        fi

        # 设置权限
        chmod 600 "$swapfile"

        # 创建交换空间
        mkswap "$swapfile"

        # 启用交换空间
        swapon "$swapfile"

        echo_green "✅ 交换文件创建并启用成功"
    fi

    # 添加到 /etc/fstab 以便开机启动
    if ! grep -q "$swapfile" /etc/fstab; then
        echo_cyan "将交换文件添加到 /etc/fstab"
        echo "$swapfile none swap sw 0 0" >> /etc/fstab
        echo_green "✅ 交换文件已添加到开机启动"
    else
        echo_green "✅ 交换文件已在 /etc/fstab 中"
    fi

    # 优化swap配置
    sysctl -w vm.swappiness=20
    sysctl -w vm.min_free_kbytes=100000

    # 持久化配置
    cat > /etc/sysctl.d/terraria-swap.conf << EOF
vm.swappiness = 20
vm.min_free_kbytes = 100000
EOF

    echo_green "🎉 虚拟内存设置完成"

    # 显示当前swap状态
    echo_cyan "当前交换空间状态："
    free -h | grep -E "(Mem|Swap)"
}

# 显示完成信息
function show_completion() {
    echo ""
    echo_blue "================================"
    echo_blue "🎮 泰拉瑞亚管理面板"
    echo_blue "   增强版部署脚本 v3.0"
    echo_blue "   老王暴躁技术流 出品"
    echo_blue "================================"
    echo ""
    echo_green "🎉 部署完成！"
    echo ""
    echo_green "📁 安装目录: $PANEL_DIR"
    echo_green "🌐 访问地址: http://YOUR_IP:$PORT"
    echo_green "🏠 本地访问: http://localhost:$PORT"
    echo ""
    echo_green "🔧 管理命令:"
    echo "  查看状态: $0 --status"
    echo "  停止服务: $0 --stop"
    echo "  重启服务: $0 --restart"
    echo "  查看日志: $0 --logs"
    echo "  清理文件: $0 --clean"
    echo ""
    echo_green "💡 提示："
    echo "  - 确保防火墙开放端口 $PORT"
    echo "  - 程序日志位于: $LOG_FILE"
    echo "  - 如需下载泰拉瑞亚服务器，请在面板中操作"
    echo ""
}

# 主程序逻辑
function main() {
    # 检查命令行参数
    case "${1:-}" in
        --status|status)
            check_service_status
            exit $?
            ;;
        --stop|stop)
            stop_service
            exit 0
            ;;
        --restart|restart)
            restart_service
            exit 0
            ;;
        --logs|logs)
            view_logs
            exit 0
            ;;
        --clean|clean)
            clean_files
            exit 0
            ;;
        --swap|swap)
            setup_swap
            exit 0
            ;;
        --help|help|-h)
            show_menu
            exit 0
            ;;
    esac

    # 交互式菜单模式
    while true; do
        show_menu
        read -r choice

        case $choice in
            0)
                set_tty
                echo_green "🧠 开始智能部署..."
                smart_deploy && start_service && check_service_status
                show_completion
                unset_tty
                break
                ;;
            1)
                set_tty
                echo_green "🌐 开始GitHub部署..."
                github_deploy && start_service && check_service_status
                show_completion
                unset_tty
                break
                ;;
            2)
                set_tty
                echo_green "📁 开始本地部署..."
                local_deploy && start_service && check_service_status
                show_completion
                unset_tty
                break
                ;;
            3)
                set_tty
                start_service
                check_service_status
                unset_tty
                ;;
            4)
                set_tty
                stop_service
                unset_tty
                ;;
            5)
                set_tty
                restart_service
                check_service_status
                unset_tty
                ;;
            6)
                check_service_status
                ;;
            7)
                set_tty
                # 检查当前版本和最新版本（如果需要）
                echo_green "🔄 更新功能开发中..."
                unset_tty
                ;;
            8)
                set_tty
                echo_green "🔄 强制重装..."
                clean_files
                smart_deploy && start_service && check_service_status
                show_completion
                unset_tty
                break
                ;;
            9)
                set_tty
                clean_files
                unset_tty
                ;;
            10)
                set_tty
                setup_swap
                unset_tty
                ;;
            11)
                view_logs
                ;;
            12)
                echo_green "👋 再见！"
                exit 0
                ;;
            *)
                echo_red "❌ 无效选择，请输入 0-12"
                continue
                ;;
        esac

        echo ""
        echo_yellow "按回车键继续..."
        read -r
    done
}

# 运行主程序
main "$@"
