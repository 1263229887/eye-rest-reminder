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

    enum ReminderKind: String { case short = "小休息"; case long = "大休息" }
    private var timer: Timer?
    @Published private(set) var elapsedSeconds = 0
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

        elapsedSeconds += 1
        let longInterval = max(1, settings.longIntervalMinutes) * 60
        let shortInterval = max(1, settings.shortIntervalMinutes) * 60
        if elapsedSeconds % longInterval == 0 {
            begin(.long, seconds: settings.longDurationMinutes * 60)
        } else if elapsedSeconds % shortInterval == 0 {
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
        elapsedSeconds = 0
    }

    func reset() {
        skip()
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

    private var secondsUntilShort: Int {
        let interval = max(1, settings.shortIntervalMinutes) * 60
        return interval - (elapsedSeconds % interval)
    }

    private var secondsUntilLong: Int {
        let interval = max(1, settings.longIntervalMinutes) * 60
        return interval - (elapsedSeconds % interval)
    }
}
