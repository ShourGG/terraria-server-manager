@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ###########################################
REM # 泰拉瑞亚管理面板 - Windows编译脚本
REM # Terraria Panel Windows Build Script
REM # 老王暴躁技术流 出品
REM ###########################################

echo ================================
echo 🎮 泰拉瑞亚管理面板编译脚本
echo    Windows Build Script
echo    老王暴躁技术流 出品
echo ================================
echo.

REM 项目信息
set PROJECT_NAME=terraria-panel
set VERSION=%1
if "%VERSION%"=="" set VERSION=v1.0.0

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set BUILD_TIME=%dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%:%dt:~12,2%

REM 目录设置
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..
set GO_SOURCE_DIR=%PROJECT_ROOT%\terraria-go
set BUILD_DIR=%SCRIPT_DIR%build
set RELEASE_DIR=%SCRIPT_DIR%release

echo 📋 编译信息:
echo   项目名称: %PROJECT_NAME%
echo   版本号: %VERSION%
echo   编译时间: %BUILD_TIME%
echo   Go源码目录: %GO_SOURCE_DIR%
echo.

REM 检查Go环境
echo 🔍 检查编译环境...
go version >nul 2>&1
if errorlevel 1 (
    echo ❌ Go未安装，请先安装Go 1.19+
    echo 📥 下载地址: https://golang.org/dl/
    pause
    exit /b 1
)

for /f "tokens=3" %%a in ('go version') do set GO_VERSION=%%a
echo ✅ Go版本: %GO_VERSION%

REM 清理构建目录
echo 🧹 清理构建目录...
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
if exist "%RELEASE_DIR%" rmdir /s /q "%RELEASE_DIR%"
mkdir "%BUILD_DIR%"
mkdir "%RELEASE_DIR%"
echo ✅ 构建目录已清理

REM 编译Go后端
echo 🔧 编译Go后端...
cd /d "%GO_SOURCE_DIR%"

if not exist "go.mod" (
    echo ❌ 未找到go.mod文件
    pause
    exit /b 1
)

echo 📦 下载Go依赖...
go mod tidy
go mod download

echo 🔨 编译多平台版本...

REM 编译参数
set LDFLAGS=-s -w -X "main.version=%VERSION%" -X "main.buildTime=%BUILD_TIME%"

REM Linux AMD64
echo   🐧 编译 Linux AMD64...
set GOOS=linux
set GOARCH=amd64
go build -ldflags="%LDFLAGS%" -o "%BUILD_DIR%\terraria-panel-linux" terraria-manager.go

REM Windows AMD64
echo   🪟 编译 Windows AMD64...
set GOOS=windows
set GOARCH=amd64
go build -ldflags="%LDFLAGS%" -o "%BUILD_DIR%\terraria-panel-windows.exe" terraria-manager.go

REM macOS AMD64
echo   🍎 编译 macOS AMD64...
set GOOS=darwin
set GOARCH=amd64
go build -ldflags="%LDFLAGS%" -o "%BUILD_DIR%\terraria-panel-macos" terraria-manager.go

REM Linux ARM64
echo   🔧 编译 Linux ARM64...
set GOOS=linux
set GOARCH=arm64
go build -ldflags="%LDFLAGS%" -o "%BUILD_DIR%\terraria-panel-linux-arm64" terraria-manager.go

echo ✅ Go后端编译完成

REM 创建发布包
echo 📦 创建发布包...
cd /d "%BUILD_DIR%"

REM Windows版本
echo   📦 打包 Windows 版本...
mkdir terraria-panel-windows
copy terraria-panel-windows.exe terraria-panel-windows\terraria-panel.exe
echo @echo off > terraria-panel-windows\start.bat
echo chcp 65001 ^>nul >> terraria-panel-windows\start.bat
echo echo 🎮 启动泰拉瑞亚管理面板... >> terraria-panel-windows\start.bat
echo echo 📍 访问地址: http://localhost:8090 >> terraria-panel-windows\start.bat
echo echo. >> terraria-panel-windows\start.bat
echo terraria-panel.exe >> terraria-panel-windows\start.bat
echo pause >> terraria-panel-windows\start.bat

REM Linux版本
echo   📦 打包 Linux 版本...
mkdir terraria-panel-linux
copy terraria-panel-linux terraria-panel-linux\terraria-panel
echo #!/bin/bash > terraria-panel-linux\start.sh
echo echo "🎮 启动泰拉瑞亚管理面板..." >> terraria-panel-linux\start.sh
echo echo "📍 访问地址: http://localhost:8090" >> terraria-panel-linux\start.sh
echo echo "" >> terraria-panel-linux\start.sh
echo ./terraria-panel >> terraria-panel-linux\start.sh

REM 创建README文件
echo # 🎮 泰拉瑞亚服务器管理面板 > terraria-panel-windows\README.md
echo. >> terraria-panel-windows\README.md
echo 版本: %VERSION% >> terraria-panel-windows\README.md
echo 编译时间: %BUILD_TIME% >> terraria-panel-windows\README.md
echo 平台: Windows >> terraria-panel-windows\README.md
echo. >> terraria-panel-windows\README.md
echo ## 🚀 快速启动 >> terraria-panel-windows\README.md
echo. >> terraria-panel-windows\README.md
echo 双击运行 `start.bat` 或直接运行 `terraria-panel.exe` >> terraria-panel-windows\README.md
echo. >> terraria-panel-windows\README.md
echo ## 🌐 访问地址 >> terraria-panel-windows\README.md
echo. >> terraria-panel-windows\README.md
echo - 管理面板: http://localhost:8090 >> terraria-panel-windows\README.md
echo - API文档: http://localhost:8090/api/ >> terraria-panel-windows\README.md
echo - WebSocket: ws://localhost:8090/ws >> terraria-panel-windows\README.md

copy terraria-panel-windows\README.md terraria-panel-linux\README.md

REM 打包文件
if exist "%ProgramFiles%\7-Zip\7z.exe" (
    echo   📦 使用7-Zip打包...
    "%ProgramFiles%\7-Zip\7z.exe" a -tzip "%RELEASE_DIR%\terraria-panel-windows.zip" terraria-panel-windows\*
    "%ProgramFiles%\7-Zip\7z.exe" a -tzip "%RELEASE_DIR%\terraria-panel-linux.zip" terraria-panel-linux\*
) else (
    echo   📦 使用PowerShell打包...
    powershell -command "Compress-Archive -Path 'terraria-panel-windows\*' -DestinationPath '%RELEASE_DIR%\terraria-panel-windows.zip' -Force"
    powershell -command "Compress-Archive -Path 'terraria-panel-linux\*' -DestinationPath '%RELEASE_DIR%\terraria-panel-linux.zip' -Force"
)

echo ✅ 发布包创建完成

REM 生成部署脚本
echo 📝 生成部署脚本...
cd /d "%SCRIPT_DIR%"

echo #!/bin/bash > "%RELEASE_DIR%\deploy-linux.sh"
echo # >> "%RELEASE_DIR%\deploy-linux.sh"
echo # 泰拉瑞亚管理面板 - Linux一键部署脚本 >> "%RELEASE_DIR%\deploy-linux.sh"
echo # 老王暴躁技术流 出品 >> "%RELEASE_DIR%\deploy-linux.sh"
echo # >> "%RELEASE_DIR%\deploy-linux.sh"
echo. >> "%RELEASE_DIR%\deploy-linux.sh"
echo echo "🎮 泰拉瑞亚管理面板 - Linux一键部署" >> "%RELEASE_DIR%\deploy-linux.sh"
echo echo "================================" >> "%RELEASE_DIR%\deploy-linux.sh"
echo. >> "%RELEASE_DIR%\deploy-linux.sh"
echo # 下载最新版本 >> "%RELEASE_DIR%\deploy-linux.sh"
echo curl -L -o terraria-panel-linux.zip "https://github.com/ShourGG/terraria-server-manager/releases/latest/download/terraria-panel-linux.zip" >> "%RELEASE_DIR%\deploy-linux.sh"
echo unzip -o terraria-panel-linux.zip >> "%RELEASE_DIR%\deploy-linux.sh"
echo cd terraria-panel-linux >> "%RELEASE_DIR%\deploy-linux.sh"
echo chmod +x terraria-panel start.sh >> "%RELEASE_DIR%\deploy-linux.sh"
echo echo "✅ 部署完成！运行 ./start.sh 启动服务" >> "%RELEASE_DIR%\deploy-linux.sh"

REM 显示构建结果
echo.
echo ================================
echo 🎉 编译完成！
echo ================================
echo.
echo 📁 构建目录: %BUILD_DIR%
echo 📦 发布目录: %RELEASE_DIR%
echo.
echo 📋 发布文件:
dir /b "%RELEASE_DIR%"
echo.
echo 🚀 下一步操作:
echo   1. 上传发布文件到GitHub Release
echo   2. 在Linux服务器运行部署脚本
echo   3. 或者手动下载对应平台的压缩包解压使用
echo.

pause
