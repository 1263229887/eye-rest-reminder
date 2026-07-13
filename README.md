# Eye Rest Reminder

极简桌面护眼提醒工具，提供 macOS 和 Windows 两个原生版本，功能完全对等。

## 功能

- 小休息：默认每 20 分钟提醒远眺 20 秒
- 大休息：默认每 60 分钟提醒活动 5 分钟
- 小休息、大休息的间隔和持续时间可直接输入
- 休息开始时自动覆盖所有显示器，显示纯黑背景、柔和灰色文字和连续进度条
- 休息结束后自动关闭全屏界面，也可按 `Esc` 或点击按钮跳过
- 主窗口与系统托盘/菜单栏均可查看下一次休息倒计时
- 支持一键暂停提醒、设置持久化和开机自启动
- 关闭主窗口后继续在托盘/菜单栏后台计时

## 目录

```text
macos/EyeRestReminder/                SwiftUI/AppKit 应用源码（macOS 13+）
macos/Info.plist                      macOS 应用包配置
windows/EyeRestReminder.Windows/      C# + WinUI 3 项目（Windows 10 1809+）
windows/README.md                     Windows 版本说明
```

## 平台实现

| 特性 | macOS (Swift) | Windows (C#) |
|---|---|---|
| UI 框架 | SwiftUI | WinUI 3 / XAML |
| 后台入口 | MenuBarExtra + LSUIElement | H.NotifyIcon.WinUI 托盘 |
| 全屏覆盖 | NSWindow + .screenSaver | 无边框 Window + HWND_TOPMOST |
| 计时器 | Foundation Timer | DispatcherQueueTimer |
| 持久化 | UserDefaults + JSON | LocalSettings + JSON |
| 开机自启动 | SMAppService.mainApp | StartupTask (TODO) |

## macOS 要求

- macOS 13 Ventura 或更高版本
- 当前测试包为 Apple Silicon `arm64` 架构
- 源码构建需要 Xcode 或 Xcode Command Line Tools

## macOS 运行

当前仓库尚未包含 `.xcodeproj`：

1. 用 Xcode 新建 macOS App，产品名填写 `EyeRestReminder`，界面选择 SwiftUI、语言选择 Swift。
2. 将 `macos/EyeRestReminder` 中的 Swift 文件加入 target。
3. 将 Deployment Target 设置为 macOS 13.0 或更高版本，然后运行。

应用启动后会显示主窗口，并在菜单栏显示眼睛图标。关闭主窗口不会退出应用，可从菜单栏重新打开。

设置会自动保存到 macOS 用户偏好。重置按钮会清零当前工作计时；关闭总开关会立即结束当前休息并暂停后续提醒。开机自启动由 macOS 登录项管理，系统可能要求用户在“系统设置 → 通用 → 登录项”中确认。

## Windows 要求

- Windows 10 版本 1809（build 17763）或更高
- .NET 8 SDK
- Visual Studio 2022（推荐，含 Windows App SDK 工作负载）

## Windows 构建与运行

### 推荐：使用 Visual Studio 2022

1. 打开 Visual Studio 2022 → "打开项目或解决方案" → 选择 `windows/EyeRestReminder.Windows/EyeRestReminder.Windows.csproj`
2. 配置目标平台为 `x64` 或 `ARM64`
3. 按 `F5` 启动调试

### 命令行构建

```bash
cd windows/EyeRestReminder.Windows
dotnet restore
dotnet build -c Debug
```

> 注意：纯命令行构建在缺失 Visual Studio 组件时会因 `Microsoft.Build.Packaging.Pri.Tasks.dll` 缺失而无法完成 PRI 资源生成。建议使用 Visual Studio 2022 进行构建。

应用启动后默认驻留系统托盘（在屏幕右下角），左键点击托盘图标打开紧凑界面，右键打开菜单。关闭主窗口会自动隐藏到托盘而非退出。

## 快速测试全屏提醒

1. 将"小休息间隔"设为 `1` 分钟。
2. 将"小休息时长"设为 `5` 秒。
3. 点击"重置"，关闭主窗口并正常使用电脑。
4. 一分钟后确认全屏提醒是否自动出现，并检查倒计时、连续进度条和跳过操作。

## 安全说明

GitHub token 不应写入代码、README 或 git 历史。建议使用 `gh auth login` 或环境变量，并在 token 暴露后立即撤销并重新生成。