#!/bin/bash

###########################################
# 泰拉瑞亚管理面板 - Linux一键部署脚本
# Terraria Panel Linux One-Click Deploy
# 老王暴躁技术流 出品
###########################################

set -e

# 配置参数
GITHUB_REPO="ShourGG/terraria-server-manager"
INSTALL_DIR="$HOME/terraria-panel"
SERVICE_PORT="8090"
PROJECT_NAME="terraria-panel-upload"

# 颜色输出
function echo_red() { echo -e "\033[0;31m$*\033[0m"; }
function echo_green() { echo -e "\033[0;32m$*\033[0m"; }
function echo_yellow() { echo -e "\033[0;33m$*\033[0m"; }
function echo_cyan() { echo -e "\033[0;36m$*\033[0m"; }
function echo_blue() { echo -e "\033[0;34m$*\033[0m"; }

echo_blue "================================"
echo_blue "🎮 泰拉瑞亚管理面板"
echo_blue "   Linux一键部署脚本"
echo_blue "   老王暴躁技术流 出品"
echo_blue "================================"

# 检测系统
ARCH=$(uname -m)
OS=$(uname -s)

echo_green "📋 系统信息:"
echo "  操作系统: $OS"
echo "  架构: $ARCH"
echo "  安装目录: $INSTALL_DIR"
echo "  服务端口: $SERVICE_PORT"
echo ""

# 检查依赖
function check_dependencies() {
    echo_cyan "🔍 检查系统依赖..."
    
    local missing_deps=()
    
    # 检查基本命令
    for cmd in curl git unzip; do
        if ! command -v $cmd >/dev/null 2>&1; then
            missing_deps+=($cmd)
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo_yellow "⚠ 缺少依赖: ${missing_deps[*]}"
        echo_cyan "正在安装依赖..."
        
        if command -v apt >/dev/null 2>&1; then
            sudo apt update
            sudo apt install -y "${missing_deps[@]}"
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y "${missing_deps[@]}"
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y "${missing_deps[@]}"
        else
            echo_red "❌ 无法自动安装依赖，请手动安装: ${missing_deps[*]}"
            exit 1
        fi
    fi
    
    echo_green "✅ 依赖检查完成"
}

# 下载项目
function download_project() {
    echo_cyan "📥 下载项目文件..."
    
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # 克隆项目
    echo_cyan "🔄 克隆GitHub项目..."
    git clone "https://github.com/$GITHUB_REPO.git" project
    cd project
    
    # 检查项目结构
    if [ ! -d "$PROJECT_NAME" ]; then
        echo_red "❌ 项目结构错误，未找到 $PROJECT_NAME 目录"
        exit 1
    fi
    
    cd "$PROJECT_NAME"
    
    # 查找可执行文件
    local executable=""
    local source_dir=""
    
    if [ -f "temp-linux/terraria-panel" ]; then
        executable="temp-linux/terraria-panel"
        source_dir="temp-linux"
        echo_green "✅ 找到Linux版本: $executable"
    elif [ -f "release/terraria-panel-linux" ]; then
        executable="release/terraria-panel-linux"
        source_dir="release"
        echo_green "✅ 找到发布版本: $executable"
    else
        echo_red "❌ 未找到可执行文件"
        echo_red "请确保项目中包含以下文件之一:"
        echo_red "  - temp-linux/terraria-panel"
        echo_red "  - release/terraria-panel-linux"
        exit 1
    fi
    
    # 安装文件
    echo_cyan "📁 安装文件到 $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    
    # 复制可执行文件
    cp "$executable" "$INSTALL_DIR/terraria-panel"
    chmod +x "$INSTALL_DIR/terraria-panel"
    
    # 复制前端文件
    if [ -d "dist" ]; then
        cp -r dist/* "$INSTALL_DIR/"
        echo_green "✅ 前端文件复制完成"
    elif [ -d "$source_dir/dist" ]; then
        cp -r "$source_dir/dist"/* "$INSTALL_DIR/"
        echo_green "✅ 前端文件复制完成"
    else
        echo_yellow "⚠ 未找到前端文件，将使用内置页面"
    fi
    
    # 创建启动脚本
    cat > "$INSTALL_DIR/start.sh" << 'EOF'
#!/bin/bash
echo "🎮 启动泰拉瑞亚管理面板..."
echo "📍 访问地址: http://localhost:8090"
echo ""

# 停止可能存在的旧进程
pkill -f "terraria-panel" 2>/dev/null || true

# 启动服务
nohup ./terraria-panel > terraria-panel.log 2>&1 &
echo $! > terraria-panel.pid

echo "✅ 服务已启动"
echo "📋 管理命令:"
echo "  查看状态: ps aux | grep terraria-panel"
echo "  停止服务: pkill -f terraria-panel"
echo "  查看日志: tail -f terraria-panel.log"
EOF
    
    chmod +x "$INSTALL_DIR/start.sh"
    
    # 创建停止脚本
    cat > "$INSTALL_DIR/stop.sh" << 'EOF'
#!/bin/bash
echo "🛑 停止泰拉瑞亚管理面板..."

if [ -f "terraria-panel.pid" ]; then
    local pid=$(cat terraria-panel.pid)
    if kill -0 $pid 2>/dev/null; then
        kill $pid
        echo "✅ 服务已停止 (PID: $pid)"
    else
        echo "⚠ 进程不存在"
    fi
    rm -f terraria-panel.pid
else
    pkill -f "terraria-panel" 2>/dev/null || true
    echo "✅ 服务已停止"
fi
EOF
    
    chmod +x "$INSTALL_DIR/stop.sh"
    
    # 创建README
    cat > "$INSTALL_DIR/README.md" << EOF
# 🎮 泰拉瑞亚服务器管理面板

## 🚀 快速启动

\`\`\`bash
./start.sh
\`\`\`

## 🛑 停止服务

\`\`\`bash
./stop.sh
\`\`\`

## 🌐 访问地址

- 管理面板: http://localhost:$SERVICE_PORT
- 如果是云服务器: http://YOUR_SERVER_IP:$SERVICE_PORT

## 📋 功能特性

- 🚀 一键启动泰拉瑞亚服务器
- 📊 实时监控服务器状态  
- 👥 玩家管理
- 🌍 世界管理
- 📝 日志查看
- 🔄 自动下载官方服务器文件

## 🔧 管理命令

\`\`\`bash
# 查看服务状态
ps aux | grep terraria-panel

# 查看日志
tail -f terraria-panel.log

# 手动启动
nohup ./terraria-panel > terraria-panel.log 2>&1 &

# 手动停止
pkill -f terraria-panel
\`\`\`

## 💡 注意事项

1. 确保防火墙开放端口 $SERVICE_PORT
2. 首次使用请在面板中创建泰拉瑞亚服务器
3. 服务器文件将自动从官方下载（约45MB）
4. 建议在云服务器上运行以获得最佳体验

---
老王暴躁技术流 出品
EOF
    
    # 清理临时文件
    cd "$HOME"
    rm -rf "$temp_dir"
    
    echo_green "✅ 项目安装完成"
}

# 启动服务
function start_service() {
    echo_cyan "🚀 启动服务..."
    
    cd "$INSTALL_DIR"
    
    # 停止可能存在的旧进程
    pkill -f "terraria-panel" 2>/dev/null || true
    sleep 1
    
    # 启动服务
    nohup ./terraria-panel > terraria-panel.log 2>&1 &
    local pid=$!
    echo $pid > terraria-panel.pid
    
    echo_green "✅ 服务启动中 (PID: $pid)"
    
    # 等待启动
    echo_cyan "⏳ 等待服务启动..."
    sleep 5
    
    # 检查服务状态
    if kill -0 $pid 2>/dev/null; then
        echo_green "✅ 进程运行正常"
        
        # 检查端口
        if netstat -tuln 2>/dev/null | grep -q ":$SERVICE_PORT " || ss -tuln 2>/dev/null | grep -q ":$SERVICE_PORT "; then
            echo_green "✅ 端口 $SERVICE_PORT 监听正常"
        else
            echo_yellow "⚠ 端口监听检查失败，但进程正在运行"
            echo_yellow "可能需要等待更长时间或检查日志"
        fi
        
        # 测试HTTP响应
        if curl -s -I "http://localhost:$SERVICE_PORT" >/dev/null 2>&1; then
            echo_green "✅ HTTP服务响应正常"
        else
            echo_yellow "⚠ HTTP服务暂未响应，可能正在初始化"
        fi
    else
        echo_red "❌ 服务启动失败"
        echo_red "请查看日志: tail -f $INSTALL_DIR/terraria-panel.log"
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
    echo_green "🌐 访问地址: http://$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP"):$SERVICE_PORT"
    echo_green "🏠 本地访问: http://localhost:$SERVICE_PORT"
    echo ""
    echo_green "🔧 管理命令:"
    echo "  启动服务: cd $INSTALL_DIR && ./start.sh"
    echo "  停止服务: cd $INSTALL_DIR && ./stop.sh"
    echo "  查看状态: ps aux | grep terraria-panel"
    echo "  查看日志: tail -f $INSTALL_DIR/terraria-panel.log"
    echo ""
    echo_green "💡 使用提示:"
    echo "  1. 打开浏览器访问管理面板"
    echo "  2. 点击'创建服务器'开始使用"
    echo "  3. 首次创建会自动下载泰拉瑞亚服务器文件"
    echo "  4. 确保防火墙开放端口 $SERVICE_PORT"
    echo ""
    echo_green "🆘 如遇问题:"
    echo "  - 查看日志: tail -f $INSTALL_DIR/terraria-panel.log"
    echo "  - 重启服务: cd $INSTALL_DIR && ./stop.sh && ./start.sh"
    echo "  - GitHub Issues: https://github.com/$GITHUB_REPO/issues"
    echo ""
}

# 主函数
function main() {
    check_dependencies
    download_project
    start_service
    show_completion
}

# 运行主函数
main "$@"
