package main

import (
	"embed"

	"github.com/getlantern/systray"
	"github.com/wailsapp/wails/v2"
	"github.com/wailsapp/wails/v2/pkg/options"
	"github.com/wailsapp/wails/v2/pkg/options/assetserver"
)

//go:embed all:frontend/dist
var assets embed.FS

var trayReady = make(chan struct{})

func main() {
	app := NewApp()

	go systray.Run(func() {
		setupTray()
		close(trayReady)
	}, nil)

	<-trayReady

	err := wails.Run(&options.App{
		Title:             "护眼提醒",
		Width:             460,
		Height:            540,
		MinWidth:          400,
		MinHeight:         380,
		DisableResize:     true,          // 禁用调整大小 + 禁用最大化按钮
		HideWindowOnClose: true,          // 点击 X → 隐藏到系统托盘 ✅
		AssetServer: &assetserver.Options{
			Assets: assets,
		},
		BackgroundColour: &options.RGBA{R: 245, G: 245, B: 245, A: 255},
		OnStartup:        app.startup,
		OnShutdown:       app.shutdown,
		Bind: []interface{}{
			app,
		},
	})

	if err != nil {
		println("Error:", err.Error())
	}
}
