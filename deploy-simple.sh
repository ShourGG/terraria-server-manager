#!/bin/bash

# 🎮 泰拉瑞亚服务器管理面板 - 简化部署脚本
# 作者：老王暴躁技术流
# 功能：直接克隆GitHub仓库并部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
GITHUB_REPO="ShourGG/terraria-server-manager"
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
    echo -e "${BLUE}   简化部署脚本 v2.0${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# 主函数
main() {
    print_title
    
    # 检查权限
    if [ "$EUID" -eq 0 ]; then
        print_message "以root用户运行"
    else
        print_message "以普通用户运行"
    fi
    
    # 检查git是否安装
    if ! command -v git >/dev/null 2>&1; then
        print_error "需要安装 git"
        print_message "Ubuntu/Debian: sudo apt update && sudo apt install -y git"
        print_message "CentOS/RHEL: sudo yum install -y git"
        exit 1
    fi
    
    print_message "克隆GitHub仓库..."
    
    # 创建临时目录
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # 克隆仓库
    if ! git clone "https://github.com/$GITHUB_REPO.git" terraria-panel; then
        print_error "克隆仓库失败"
        exit 1
    fi
    
    cd terraria-panel
    
    print_message "检查仓库内容..."
    ls -la
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    
    # 复制文件 - 直接复制所有需要的文件
    print_message "安装到: $INSTALL_DIR"
    
    # 复制前端文件
    if [ -d "dist" ]; then
        cp -r dist "$INSTALL_DIR/"
        print_message "✅ 复制前端文件"
    fi
    
    # 复制后端文件
    if [ -f "release/terraria-panel-linux" ]; then
        cp release/terraria-panel-linux "$INSTALL_DIR/terraria-panel"
        chmod +x "$INSTALL_DIR/terraria-panel"
        print_message "✅ 复制后端程序"
    fi
    
    # 创建启动脚本
    cat > "$INSTALL_DIR/start.sh" << 'EOF'
#!/bin/bash
echo "🎮 启动泰拉瑞亚服务器管理面板..."
echo "📁 工作目录: $(pwd)"
echo "🌐 访问地址: http://localhost:8090"
echo ""
./terraria-panel
EOF
    chmod +x "$INSTALL_DIR/start.sh"
    print_message "✅ 创建启动脚本"
    
    # 清理临时文件
    cd "$HOME"
    rm -rf "$temp_dir"
    
    print_message "安装完成！"
    
    # 启动服务
    print_message "启动服务..."
    cd "$INSTALL_DIR"
    nohup ./terraria-panel > terraria-panel.log 2>&1 &
    echo $! > terraria-panel.pid
    
    # 显示完成信息
    echo ""
    print_title
    print_message "🎉 部署完成！"
    echo ""
    print_message "📁 安装目录: $INSTALL_DIR"
    print_message "🌐 访问地址: http://localhost:8090"
    print_message "📚 使用文档: https://github.com/$GITHUB_REPO"
    echo ""
    print_message "🔧 管理命令:"
    echo "  启动服务: cd $INSTALL_DIR && ./start.sh"
    echo "  停止服务: kill \$(cat $INSTALL_DIR/terraria-panel.pid)"
    echo "  查看日志: tail -f $INSTALL_DIR/terraria-panel.log"
    echo ""
}

# 运行主函数
main "$@"
