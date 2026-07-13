# Eye Rest Reminder

极简桌面护眼提醒工具，面向 macOS 和 Windows。

## 功能

- 小休息：默认每 20 分钟提醒远眺 20 秒
- 大休息：默认每 60 分钟提醒活动 5 分钟
- 小休息、大休息的间隔和持续时间可自定义
- 全屏倒计时、进度条和跳过按钮
- 关闭窗口后继续在后台计时
- 尽量使用系统原生技术：macOS 使用 SwiftUI/AppKit，Windows 使用 WinUI 3/Windows App SDK

## 目录

```text
macos/EyeRestReminder/   SwiftUI macOS 应用（可直接用 Xcode 打开源码）
windows/                 WinUI 3 项目设计与后续工程入口
```

## macOS 运行（当前优先支持）

1. 用 Xcode 新建 macOS App，产品名填写 `EyeRestReminder`，界面选择 SwiftUI、语言选择 Swift。
2. 将 `macos/EyeRestReminder` 中的 Swift 文件加入 target。
3. 运行即可。应用会显示在菜单栏，关闭弹出面板后仍会后台计时。

设置会自动保存到 macOS 的用户偏好；倒计时期间可直接跳过，重置按钮会清零当前工作计时。

## Windows 计划

Windows 版本使用 C# + WinUI 3，保持相同的计时和设置模型。详见 `windows/README.md`。

## 安全说明

GitHub token 不应写入代码、README 或 git 历史。建议使用 `gh auth login` 或环境变量，并在 token 暴露后立即撤销并重新生成。
