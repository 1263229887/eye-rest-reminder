import SwiftUI

@main
struct EyeRestReminderApp: App {
    @StateObject private var scheduler = ReminderScheduler()

    var body: some Scene {
        MenuBarExtra("护眼提醒", systemImage: "eye") {
            ContentView(scheduler: scheduler)
                .frame(width: 320)
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
