import Foundation
import Combine

struct ReminderSettings: Codable {
    var shortIntervalMinutes = 20
    var shortDurationSeconds = 20
    var longIntervalMinutes = 60
    var longDurationMinutes = 5
}

final class ReminderScheduler: ObservableObject {
    @Published var settings = ReminderSettings()
    @Published var activeReminder: ReminderKind?
    @Published var remainingSeconds = 0
    @Published var isRunning = false
    @Published var isEnabled = true
    @Published private(set) var reminderEndDate: Date?

    enum ReminderKind: String { case short = "小休息"; case long = "大休息"; case both = "小休息 + 大休息" }
    private var timer: Timer?
    /// 小休息独立计时，不受大休息跳过影响
    @Published private(set) var shortElapsed = 0
    /// 大休息独立计时，不受小休息跳过影响
    @Published private(set) var longElapsed = 0
    private let defaults = UserDefaults.standard
    private let settingsKey = "reminderSettings"
    private let enabledKey = "remindersEnabled"

    init() {
        if let data = defaults.data(forKey: settingsKey),
           let saved = try? JSONDecoder().decode(ReminderSettings.self, from: data) {
            settings = saved
        }
        if defaults.object(forKey: enabledKey) != nil {
            isEnabled = defaults.bool(forKey: enabledKey)
        }
        start()
    }

    func start() {
        timer?.invalidate()
        // A one-second heartbeat keeps elapsed time accurate while allowing settings
        // changes to take effect without rebuilding the scheduler.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        isRunning = isEnabled
    }

    func tick() {
        guard isEnabled else { return }
        if activeReminder != nil {
            guard let reminderEndDate else { return }
            let remaining = reminderEndDate.timeIntervalSinceNow
            if remaining <= 0 {
                skip()
            } else {
                remainingSeconds = Int(ceil(remaining))
            }
            return
        }

        shortElapsed += 1
        longElapsed += 1

        let shortInterval = max(1, settings.shortIntervalMinutes) * 60
        let longInterval = max(1, settings.longIntervalMinutes) * 60

        let shouldShort = shortElapsed % shortInterval == 0
        let shouldLong = longElapsed % longInterval == 0

        if shouldShort && shouldLong {
            // 同时到期，以大休息为准并合并展示
            begin(.both, seconds: settings.longDurationMinutes * 60)
        } else if shouldLong {
            begin(.long, seconds: settings.longDurationMinutes * 60)
        } else if shouldShort {
            begin(.short, seconds: settings.shortDurationSeconds)
        }
    }

    func begin(_ kind: ReminderKind, seconds: Int) {
        guard isEnabled else { return }
        activeReminder = kind
        remainingSeconds = seconds
        reminderEndDate = Date().addingTimeInterval(TimeInterval(seconds))
    }

    func skip() {
        activeReminder = nil
        remainingSeconds = 0
        reminderEndDate = nil
        // 不重置 shortElapsed / longElapsed，让各自计时器独立累计
    }

    func reset() {
        skip()
        shortElapsed = 0
        longElapsed = 0
        start()
    }

    func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        isRunning = enabled
        defaults.set(enabled, forKey: enabledKey)
        if !enabled {
            skip()
        }
    }

    var nextReminder: ReminderKind {
        secondsUntilLong <= secondsUntilShort ? .long : .short
    }

    var secondsUntilNextReminder: Int {
        min(secondsUntilShort, secondsUntilLong)
    }

    var nextReminderInterval: Int {
        nextReminder == .long
            ? max(1, settings.longIntervalMinutes) * 60
            : max(1, settings.shortIntervalMinutes) * 60
    }

    /// 小休息间隔（秒）
    var shortInterval: Int {
        max(1, settings.shortIntervalMinutes) * 60
    }

    /// 大休息间隔（秒）
    var longInterval: Int {
        max(1, settings.longIntervalMinutes) * 60
    }

    var secondsUntilShort: Int {
        let interval = max(1, settings.shortIntervalMinutes) * 60
        return interval - (shortElapsed % interval)
    }

    var secondsUntilLong: Int {
        let interval = max(1, settings.longIntervalMinutes) * 60
        return interval - (longElapsed % interval)
    }
}
