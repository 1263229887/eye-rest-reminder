import AppKit
import Combine
import SwiftUI

final class ReminderOverlayController: ObservableObject {
    private let scheduler: ReminderScheduler
    private var windows: [NSWindow] = []
    private var cancellable: AnyCancellable?

    init(scheduler: ReminderScheduler) {
        self.scheduler = scheduler
        cancellable = scheduler.$activeReminder
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] kind in
                if kind == nil {
                    self?.hide()
                } else {
                    self?.show()
                }
            }
    }

    private func show() {
        hide()
        NSApp.activate(ignoringOtherApps: true)
        NSSound(named: "Glass")?.play()

        windows = NSScreen.screens.map { screen in
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = .screenSaver
            window.backgroundColor = .black
            window.isOpaque = true
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            window.contentView = NSHostingView(rootView: ReminderOverlayView(scheduler: scheduler))
            window.makeKeyAndOrderFront(nil)
            return window
        }
    }

    private func hide() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }
}

struct ReminderOverlayView: View {
    @ObservedObject var scheduler: ReminderScheduler

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 34) {
                Text(message)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(Color(white: 0.66))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                    let remaining = remaining(at: timeline.date)
                    VStack(spacing: 24) {
                        Text(time(Int(ceil(remaining))))
                            .font(.system(size: 88, weight: .medium, design: .rounded))
                            .monospacedDigit()
                        SmoothProgressBar(progress: 1 - remaining / Double(total))
                            .frame(maxWidth: 560, minHeight: 5, maxHeight: 5)
                    }
                }

                Button("跳过本次休息") { scheduler.skip() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut(.cancelAction)
            }
            .foregroundStyle(Color(white: 0.62))
            .padding(48)
            .frame(maxWidth: 900)
        }
    }

    private var kind: ReminderScheduler.ReminderKind {
        scheduler.activeReminder ?? .short
    }

    private var message: String {
        kind == .short
            ? "看向约 6 米以外，让眼睛自然放松。"
            : "离开屏幕走一走，舒展肩颈和腰背。"
    }

    private var total: Int {
        kind == .short
            ? scheduler.settings.shortDurationSeconds
            : scheduler.settings.longDurationMinutes * 60
    }

    private func time(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func remaining(at date: Date) -> TimeInterval {
        guard let endDate = scheduler.reminderEndDate else { return 0 }
        return min(Double(total), max(0, endDate.timeIntervalSince(date)))
    }
}

private struct SmoothProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(white: 0.15))
                Capsule()
                    .fill(Color(white: 0.46))
                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
            }
        }
    }
}
