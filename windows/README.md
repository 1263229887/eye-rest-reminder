# Windows 原生实现计划

> 当前目录仅包含设计说明，尚无可构建的 Windows 应用。

建议使用 Visual Studio 2022 的 **Blank App, Packaged (WinUI 3 in Desktop)** 模板，技术栈为 C#、WinUI 3、Windows App SDK。

实现对应关系：

- `DispatcherQueueTimer` 推进工作计时，休息进度使用高频界面刷新并以目标结束时间为准
- `ContentDialog` 或独立无边框窗口承载全屏休息倒计时
- `ProgressBar` 展示连续进度，`Button` 提供跳过
- `ApplicationData.Current.LocalSettings` 持久化四个时长配置和提醒总开关
- `NotifyIcon`（Windows App SDK + 社区托盘组件）提供后台菜单栏入口
- Windows 启动任务提供开机自启动选项

项目名称建议为 `EyeRestReminder.Windows`，与 macOS 版本共用本 README 定义的默认值和行为。
