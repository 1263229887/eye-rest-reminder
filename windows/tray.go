package main

import (
	"github.com/getlantern/systray"
)

func setupTray() {
	// On Windows, SetTemplateIcon expects .ico format.
	// We skip custom icon here and use the default application icon.
	// Alternative: embed a proper .ico file.

	systray.SetTooltip("护眼提醒")

	showItem := systray.AddMenuItem("打开主界面", "显示主窗口")
	systray.AddSeparator()
	pauseItem := systray.AddMenuItem("暂停提醒", "暂停/恢复提示")
	systray.AddSeparator()
	quitItem := systray.AddMenuItem("退出", "退出应用")

	go func() {
		for {
			select {
			case <-showItem.ClickedCh:
				showMainWindowFn()
			case <-pauseItem.ClickedCh:
				toggleEnabledFn()
			case <-quitItem.ClickedCh:
				quitAppFn()
			}
		}
	}()
}

var (
	showMainWindowFn = func() {}
	toggleEnabledFn  = func() {}
	quitAppFn        = func() {}
)
