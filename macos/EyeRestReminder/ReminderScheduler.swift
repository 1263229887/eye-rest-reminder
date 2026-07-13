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

    enum ReminderKind: String { case short = "小休息"; case long = "大休息" }
    private var timer: Timer?
    private var elapsedSeconds = 0
    private let defaults = UserDefaults.standard
    private let settingsKey = "reminderSettings"

    init() {
        if let data = defaults.data(forKey: settingsKey),
           let saved = try? JSONDecoder().decode(ReminderSettings.self, from: data) {
            settings = saved
        }
        start()
    }

    func start() {
        timer?.invalidate()
        // A one-second heartbeat keeps elapsed time accurate while allowing settings
        // changes to take effect without rebuilding the scheduler.
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        isRunning = true
    }

    func tick() {
        if activeReminder != nil {
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                skip()
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
        activeReminder = kind
        remainingSeconds = seconds
    }

    func skip() {
        activeReminder = nil
        remainingSeconds = 0
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
}
