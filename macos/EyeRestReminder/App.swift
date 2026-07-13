import SwiftUI

@main
struct EyeRestReminderApp: App {
    @StateObject private var scheduler: ReminderScheduler
    @StateObject private var overlayController: ReminderOverlayController
    @StateObject private var launchAtLogin = LaunchAtLoginController()

    init() {
        let scheduler = ReminderScheduler()
        _scheduler = StateObject(wrappedValue: scheduler)
        _overlayController = StateObject(wrappedValue: ReminderOverlayController(scheduler: scheduler))
    }

    var body: some Scene {
        Window("护眼提醒", id: "main") {
            ContentView(scheduler: scheduler, launchAtLogin: launchAtLogin)
                .frame(minWidth: 420, minHeight: 360)
                .padding(24)
        }
        .defaultSize(width: 480, height: 420)

        MenuBarExtra("护眼提醒", systemImage: "eye") {
            MenuBarContentView(scheduler: scheduler, launchAtLogin: launchAtLogin)
                .frame(width: 320)
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
