# Windows 原生实现

建议使用 Visual Studio 2022 的 **Blank App, Packaged (WinUI 3 in Desktop)** 模板，技术栈为 C#、WinUI 3、Windows App SDK。

实现对应关系：

- `DispatcherQueueTimer` 每分钟推进工作计时
- `ContentDialog` 或独立无边框窗口承载全屏休息倒计时
- `ProgressBar` 展示剩余进度，`Button` 提供跳过
- `ApplicationData.Current.LocalSettings` 持久化四个时长配置
- `NotifyIcon`（Windows App SDK + 社区托盘组件）提供后台菜单栏入口

项目名称建议为 `EyeRestReminder.Windows`，与 macOS 版本共用本 README 定义的默认值和行为。
