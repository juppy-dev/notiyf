import AppKit
import SwiftUI

@MainActor
final class MarqueeOverlayPresenter {
    private var window: NSWindow?
    private var hostingView: NSHostingView<MarqueeOverlayView>?
    private var reminder: Reminder?

    var onSnooze: ((Reminder.ID, Int) -> Void)?
    var onDismiss: ((Reminder.ID) -> Void)?

    func show(reminder: Reminder) {
        self.reminder = reminder

        let overlayView = MarqueeOverlayView(
            reminder: reminder,
            onSnooze: { [weak self] minutes in
                guard let id = self?.reminder?.id else { return }
                self?.hide()
                self?.onSnooze?(id, minutes)
            },
            onDismiss: { [weak self] in
                guard let id = self?.reminder?.id else { return }
                self?.hide()
                self?.onDismiss?(id)
            }
        )

        if window == nil {
            let screenFrame = NSScreen.main?.frame ?? .zero
            let frame = NSRect(x: 0, y: screenFrame.height - 120, width: screenFrame.width, height: 96)
            let window = NSWindow(
                contentRect: frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.ignoresMouseEvents = false
            self.window = window
        }

        let hostingView = NSHostingView(rootView: overlayView)
        self.hostingView = hostingView
        window?.contentView = hostingView
        window?.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
        reminder = nil
    }
}

private struct MarqueeOverlayView: View {
    let reminder: Reminder
    let onSnooze: (Int) -> Void
    let onDismiss: () -> Void

    @State private var now = Date()
    @State private var showControls = false
    @State private var textOffset: CGFloat = 900

    private var phase: ReminderDisplayPhase {
        ReminderDisplayPhase.phase(for: reminder.dueAt, now: now)
    }

    private var message: String {
        switch phase {
        case .countdown:
            let seconds = max(0, Int(reminder.dueAt.timeIntervalSince(now)))
            return "\(reminder.title) in \(seconds / 60)m \(seconds % 60)s"
        case .dueNow:
            return "\(reminder.title) is starting now"
        case .overdue:
            let seconds = max(0, Int(now.timeIntervalSince(reminder.dueAt)))
            return "\(reminder.title) started \(seconds / 60)m ago"
        }
    }

    private var stripHeight: CGFloat {
        phase == .dueNow ? 96 : 72
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Rectangle()
                .fill(phase == .dueNow ? Color.red : Color.yellow)
                .frame(height: stripHeight)
                .shadow(radius: 12)

            Text(message.uppercased() + "  -  " + message.uppercased() + "  -  ")
                .font(.system(size: phase == .dueNow ? 34 : 28, weight: .black, design: .rounded))
                .foregroundStyle(phase == .dueNow ? .white : .black)
                .lineLimit(1)
                .offset(x: textOffset)
                .onAppear {
                    animate()
                }
                .onChange(of: phase) { _, _ in
                    animate()
                }

            if showControls {
                HStack(spacing: 8) {
                    Button("Snooze 5m") { onSnooze(5) }
                    Button("Snooze 10m") { onSnooze(10) }
                    Button("Dismiss") { onDismiss() }
                        .keyboardShortcut(.return)
                }
                .padding(10)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.trailing, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            revealControls()
        }
        .onExitCommand {
            showControls = false
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
    }

    private func revealControls() {
        showControls = true

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(8))
            showControls = false
        }
    }

    private func animate() {
        textOffset = 900
        withAnimation(.linear(duration: phase == .dueNow ? 2.5 : 5).repeatForever(autoreverses: false)) {
            textOffset = -900
        }
    }
}
