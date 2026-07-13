import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var scheduler: ReminderScheduler
    @ObservedObject var launchAtLogin: LaunchAtLoginController
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("护眼提醒")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { scheduler.isEnabled },
                    set: { scheduler.setEnabled($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .help(scheduler.isEnabled ? "关闭提醒" : "开启提醒")
            }
            if !scheduler.isEnabled {
                Text("提醒已暂停")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            } else if let kind = scheduler.activeReminder {
                Text(kind.rawValue).font(.title3)
                Text(time(scheduler.remainingSeconds)).font(.system(size: 42, weight: .semibold, design: .rounded))
                ProgressView(value: Double(scheduler.remainingSeconds), total: Double(total(for: kind)))
                Button("跳过休息") { scheduler.skip() }
                    .keyboardShortcut(.cancelAction)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("距离下一次\(scheduler.nextReminder.rawValue)")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("重置") { scheduler.reset() }
                            .buttonStyle(.link)
                    }
                    Text(time(scheduler.secondsUntilNextReminder))
                        .font(.system(size: compact ? 36 : 52, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    ProgressView(
                        value: Double(scheduler.nextReminderInterval - scheduler.secondsUntilNextReminder),
                        total: Double(scheduler.nextReminderInterval)
                    )
                }
                if !compact {
                    Divider()
                    VStack(spacing: 10) {
                        NumberSettingRow(title: "小休息间隔", value: $scheduler.settings.shortIntervalMinutes, range: 1...240, unit: "分钟")
                        NumberSettingRow(title: "小休息时长", value: $scheduler.settings.shortDurationSeconds, range: 5...300, unit: "秒")
                        NumberSettingRow(title: "大休息间隔", value: $scheduler.settings.longIntervalMinutes, range: 1...480, unit: "分钟")
                        NumberSettingRow(title: "大休息时长", value: $scheduler.settings.longDurationMinutes, range: 1...60, unit: "分钟")
                    }
                    Divider()
                    Toggle("开机时自动启动", isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { launchAtLogin.setEnabled($0) }
                    ))
                    if let error = launchAtLogin.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    Text("关闭窗口后，计时仍会在菜单栏后台运行。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: scheduler.settings.shortIntervalMinutes) { _ in scheduler.saveSettings() }
        .onChange(of: scheduler.settings.shortDurationSeconds) { _ in scheduler.saveSettings() }
        .onChange(of: scheduler.settings.longIntervalMinutes) { _ in scheduler.saveSettings() }
        .onChange(of: scheduler.settings.longDurationMinutes) { _ in scheduler.saveSettings() }
    }

    private func time(_ seconds: Int) -> String { String(format: "%02d:%02d", seconds / 60, seconds % 60) }
    private func total(for kind: ReminderScheduler.ReminderKind) -> Int {
        kind == .short ? scheduler.settings.shortDurationSeconds : scheduler.settings.longDurationMinutes * 60
    }
}

private struct NumberSettingRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 72)
                .onSubmit { value = min(max(value, range.lowerBound), range.upperBound) }
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
    }
}

struct MenuBarContentView: View {
    @ObservedObject var scheduler: ReminderScheduler
    @ObservedObject var launchAtLogin: LaunchAtLoginController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 12) {
            ContentView(scheduler: scheduler, launchAtLogin: launchAtLogin, compact: true)
            Divider()
            Button("打开主界面") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
