import SwiftUI

struct ContentView: View {
    @ObservedObject var scheduler: ReminderScheduler

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("护眼提醒", systemImage: "eye")
                .font(.headline)
            if let kind = scheduler.activeReminder {
                Text(kind.rawValue).font(.title3)
                Text(time(scheduler.remainingSeconds)).font(.system(size: 42, weight: .semibold, design: .rounded))
                ProgressView(value: Double(scheduler.remainingSeconds), total: Double(total(for: kind)))
                Button("跳过休息") { scheduler.skip() }
                    .keyboardShortcut(.cancelAction)
            } else {
                Text("计时运行中").foregroundStyle(.secondary)
                Divider()
                Stepper("小休息间隔：\(scheduler.settings.shortIntervalMinutes) 分钟", value: $scheduler.settings.shortIntervalMinutes, in: 1...240)
                Stepper("小休息时长：\(scheduler.settings.shortDurationSeconds) 秒", value: $scheduler.settings.shortDurationSeconds, in: 5...300)
                Stepper("大休息间隔：\(scheduler.settings.longIntervalMinutes) 分钟", value: $scheduler.settings.longIntervalMinutes, in: 1...480)
                Stepper("大休息时长：\(scheduler.settings.longDurationMinutes) 分钟", value: $scheduler.settings.longDurationMinutes, in: 1...60)
            }
        }
    }

    private func time(_ seconds: Int) -> String { String(format: "%02d:%02d", seconds / 60, seconds % 60) }
    private func total(for kind: ReminderScheduler.ReminderKind) -> Int {
        kind == .short ? scheduler.settings.shortDurationSeconds : scheduler.settings.longDurationMinutes * 60
    }
}
