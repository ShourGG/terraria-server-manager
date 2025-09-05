# 🎮 泰拉瑞亚服务器管理面板 - Windows一键部署脚本
# 作者：老王暴躁技术流
# 功能：自动下载并部署面板

param(
    [string]$InstallPath = "$env:USERPROFILE\terraria-panel"
)

# 项目信息
$GitHubRepo = "your-username/terraria-panel"
$GitHubAPI = "https://api.github.com/repos/$GitHubRepo"
$ServiceName = "terraria-panel"

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colors = @{
        "Red" = "Red"
        "Green" = "Green"
        "Yellow" = "Yellow"
        "Blue" = "Blue"
        "White" = "White"
    }
    
    Write-Host $Message -ForegroundColor $colors[$Color]
}

function Write-Title {
    Write-Host "================================" -ForegroundColor Blue
    Write-Host "🎮 泰拉瑞亚服务器管理面板" -ForegroundColor Blue
    Write-Host "   Windows一键部署脚本 v1.0" -ForegroundColor Blue
    Write-Host "================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARN] $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

# 检测系统架构
function Get-SystemInfo {
    Write-Info "检测系统信息..."
    
    $arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }
    $platform = "windows"
    
    Write-Info "检测到系统: $platform-$arch"
    
    return @{
        Platform = $platform
        Architecture = $arch
    }
}

# 获取最新版本
function Get-LatestVersion {
    Write-Info "获取最新版本信息..."
    
    try {
        $response = Invoke-RestMethod -Uri "$GitHubAPI/releases/latest" -Method Get
        $version = $response.tag_name
        
        if (-not $version) {
            throw "无法获取版本信息"
        }
        
        Write-Info "最新版本: $version"
        return $version
    }
    catch {
        Write-Error "获取版本信息失败: $($_.Exception.Message)"
        exit 1
    }
}

# 下载发布包
function Download-Release {
    param(
        [string]$Version,
        [string]$Platform
    )
    
    $filename = "terraria-panel-$Platform.zip"
    $downloadUrl = "https://github.com/$GitHubRepo/releases/download/$Version/$filename"
    
    Write-Info "下载发布包: $filename"
    
    # 创建临时目录
    $tempDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    $zipPath = Join-Path $tempDir $filename
    
    try {
        # 下载文件
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
        
        if (-not (Test-Path $zipPath)) {
            throw "下载失败"
        }
        
        Write-Info "解压文件..."
        
        # 解压文件
        $extractPath = Join-Path $tempDir "extracted"
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        
        # 创建安装目录
        if (Test-Path $InstallPath) {
            Write-Warning "安装目录已存在，将覆盖: $InstallPath"
            Remove-Item -Path $InstallPath -Recurse -Force
        }
        
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        
        # 复制文件
        Write-Info "安装到: $InstallPath"
        $sourceDir = Join-Path $extractPath "terraria-panel-$Platform"
        Copy-Item -Path "$sourceDir\*" -Destination $InstallPath -Recurse -Force
        
        Write-Info "安装完成！"
    }
    catch {
        Write-Error "下载或安装失败: $($_.Exception.Message)"
        exit 1
    }
    finally {
        # 清理临时文件
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# 创建Windows服务
function Install-WindowsService {
    Write-Info "检查是否需要创建Windows服务..."
    
    # 检查是否以管理员身份运行
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if ($isAdmin) {
        Write-Info "以管理员身份运行，创建Windows服务..."
        
        $servicePath = Join-Path $InstallPath "terraria-panel.exe"
        
        # 检查服务是否已存在
        $existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($existingService) {
            Write-Warning "服务已存在，先停止并删除..."
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            & sc.exe delete $ServiceName
            Start-Sleep -Seconds 2
        }
        
        # 创建服务
        & sc.exe create $ServiceName binPath= "`"$servicePath`"" start= auto DisplayName= "Terraria Server Management Panel"
        & sc.exe description $ServiceName "泰拉瑞亚服务器管理面板"
        
        Write-Info "Windows服务已创建"
        return $true
    }
    else {
        Write-Warning "非管理员权限，跳过Windows服务创建"
        return $false
    }
}

# 启动服务
function Start-Service {
    param([bool]$UseWindowsService)
    
    if ($UseWindowsService) {
        Write-Info "启动Windows服务..."
        Start-Service -Name $ServiceName
        
        $service = Get-Service -Name $ServiceName
        Write-Info "服务状态: $($service.Status)"
    }
    else {
        Write-Info "手动启动服务..."
        
        $exePath = Join-Path $InstallPath "terraria-panel.exe"
        $logPath = Join-Path $InstallPath "terraria-panel.log"
        
        # 启动进程
        $process = Start-Process -FilePath $exePath -WorkingDirectory $InstallPath -WindowStyle Hidden -PassThru
        
        # 保存PID
        $pidPath = Join-Path $InstallPath "terraria-panel.pid"
        $process.Id | Out-File -FilePath $pidPath -Encoding UTF8
        
        Write-Info "服务已在后台启动"
        Write-Info "进程ID: $($process.Id)"
        Write-Info "PID文件: $pidPath"
    }
}

# 显示完成信息
function Show-Completion {
    param([bool]$UseWindowsService)
    
    Write-Host ""
    Write-Title
    Write-Info "🎉 部署完成！"
    Write-Host ""
    Write-Info "📁 安装目录: $InstallPath"
    Write-Info "🌐 访问地址: http://localhost:8090"
    Write-Info "📚 使用文档: https://github.com/$GitHubRepo"
    Write-Host ""
    Write-Info "🔧 管理命令:"
    
    if ($UseWindowsService) {
        Write-Host "  启动服务: Start-Service -Name $ServiceName"
        Write-Host "  停止服务: Stop-Service -Name $ServiceName"
        Write-Host "  重启服务: Restart-Service -Name $ServiceName"
        Write-Host "  查看状态: Get-Service -Name $ServiceName"
        Write-Host "  删除服务: sc.exe delete $ServiceName (需要管理员权限)"
    }
    else {
        $batPath = Join-Path $InstallPath "start.bat"
        $pidPath = Join-Path $InstallPath "terraria-panel.pid"
        Write-Host "  启动服务: $batPath"
        Write-Host "  停止服务: taskkill /PID `$(Get-Content '$pidPath') /F"
        Write-Host "  查看进程: Get-Process -Name terraria-panel"
    }
    Write-Host ""
    
    # 创建桌面快捷方式
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "泰拉瑞亚管理面板.url"
    
    @"
[InternetShortcut]
URL=http://localhost:8090
IconFile=$InstallPath\terraria-panel.exe
IconIndex=0
"@ | Out-File -FilePath $shortcutPath -Encoding UTF8
    
    Write-Info "🖥️ 已创建桌面快捷方式"
}

# 主函数
function Main {
    Write-Title
    
    # 检查PowerShell版本
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Error "需要PowerShell 5.0或更高版本"
        exit 1
    }
    
    # 检查网络连接
    try {
        Test-NetConnection -ComputerName "github.com" -Port 443 -InformationLevel Quiet | Out-Null
    }
    catch {
        Write-Error "无法连接到GitHub，请检查网络连接"
        exit 1
    }
    
    # 执行部署步骤
    $systemInfo = Get-SystemInfo
    $version = Get-LatestVersion
    Download-Release -Version $version -Platform $systemInfo.Platform
    $useService = Install-WindowsService
    Start-Service -UseWindowsService $useService
    Show-Completion -UseWindowsService $useService
}

# 运行主函数
try {
    Main
}
catch {
    Write-Error "部署失败: $($_.Exception.Message)"
    exit 1
}
