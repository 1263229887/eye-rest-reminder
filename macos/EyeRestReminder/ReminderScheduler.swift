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
    private var countdownTimer: Timer?
    private var elapsedMinutes = 0

    init() { start() }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.tick() }
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, self.activeReminder != nil else { return }
            if self.remainingSeconds > 0 { self.remainingSeconds -= 1 } else { self.skip() }
        }
        isRunning = true
    }

    func tick() {
        elapsedMinutes += 1
        if elapsedMinutes % max(1, settings.longIntervalMinutes) == 0 {
            begin(.long, seconds: settings.longDurationMinutes * 60)
        } else if elapsedMinutes % max(1, settings.shortIntervalMinutes) == 0 {
            begin(.short, seconds: settings.shortDurationSeconds)
        }
    }

    func begin(_ kind: ReminderKind, seconds: Int) {
        activeReminder = kind
        remainingSeconds = seconds
    }

    func skip() { activeReminder = nil; remainingSeconds = 0 }
}
