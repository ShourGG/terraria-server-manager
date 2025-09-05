#!/bin/bash

###########################################
# 泰拉瑞亚管理面板 - 启动脚本
# Terraria Panel Start Script
# 老王暴躁技术流 出品
###########################################

# 颜色输出
function echo_red() { echo -e "\033[0;31m$*\033[0m"; }
function echo_green() { echo -e "\033[0;32m$*\033[0m"; }
function echo_yellow() { echo -e "\033[0;33m$*\033[0m"; }
function echo_cyan() { echo -e "\033[0;36m$*\033[0m"; }
function echo_blue() { echo -e "\033[0;34m$*\033[0m"; }

echo_blue "================================"
echo_blue "🎮 泰拉瑞亚服务器管理面板"
echo_blue "   老王暴躁技术流 出品"
echo_blue "================================"

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 检查可执行文件
EXECUTABLE=""
if [ -f "terraria-panel-linux-new" ]; then
    EXECUTABLE="terraria-panel-linux-new"
elif [ -f "terraria-panel-linux" ]; then
    EXECUTABLE="terraria-panel-linux"
elif [ -f "terraria-panel" ]; then
    EXECUTABLE="terraria-panel"
else
    echo_red "❌ 未找到可执行文件"
    echo_red "请确保以下文件之一存在："
    echo_red "  - terraria-panel-linux-new"
    echo_red "  - terraria-panel-linux"
    echo_red "  - terraria-panel"
    exit 1
fi

echo_green "✅ 找到可执行文件: $EXECUTABLE"

# 设置权限
chmod +x "$EXECUTABLE"

# 停止可能存在的旧进程
echo_cyan "🛑 停止旧进程..."
pkill -f "terraria-panel" 2>/dev/null || true
sleep 1

# 启动服务
echo_cyan "🚀 启动泰拉瑞亚管理面板..."
echo_green "📍 访问地址: http://localhost:8090"
echo_green "🌐 如果是云服务器: http://YOUR_SERVER_IP:8090"
echo ""

# 检查是否在后台运行
if [ "$1" = "--daemon" ] || [ "$1" = "-d" ]; then
    echo_cyan "🔄 后台模式启动..."
    nohup "./$EXECUTABLE" > terraria-panel.log 2>&1 &
    PID=$!
    echo $PID > terraria-panel.pid
    echo_green "✅ 服务已在后台启动 (PID: $PID)"
    echo_green "📋 管理命令:"
    echo "  查看状态: ps aux | grep terraria-panel"
    echo "  停止服务: pkill -f terraria-panel"
    echo "  查看日志: tail -f terraria-panel.log"
else
    echo_cyan "🎯 前台模式启动（按Ctrl+C停止）..."
    echo ""
    "./$EXECUTABLE"
fi
