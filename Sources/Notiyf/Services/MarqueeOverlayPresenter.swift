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

        let screenFrame = OverlayScreenPlacement.frame(
            mainFrame: NSScreen.main?.frame,
            candidateFrames: NSScreen.screens.map(\.frame),
            pointerLocation: NSEvent.mouseLocation
        )
        let frame = NSRect(x: screenFrame.minX, y: screenFrame.maxY - 120, width: screenFrame.width, height: 96)

        if window == nil {
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

        window?.setFrame(frame, display: true)
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

enum OverlayScreenPlacement {
    static func frame(mainFrame: CGRect?, candidateFrames: [CGRect], pointerLocation: CGPoint) -> CGRect {
        if let mainFrame, !mainFrame.isEmpty {
            return mainFrame
        }

        if let pointerFrame = candidateFrames.first(where: { $0.contains(pointerLocation) }) {
            return pointerFrame
        }

        return candidateFrames.first ?? .zero
    }
}

private struct MarqueeOverlayView: View {
    let reminder: Reminder
    let onSnooze: (Int) -> Void
    let onDismiss: () -> Void

    @State private var now = Date()
    @State private var showControls = false
    @State private var tickerStart = Date()
    @State private var hideControlsTask: Task<Void, Never>?

    private var phase: ReminderDisplayPhase {
        ReminderDisplayPhase.phase(for: reminder.dueAt, now: now)
    }

    private var tickerMessage: String {
        switch phase {
        case .countdown:
            return "\(reminder.title)  •  starts in \(clockString(for: max(0, Int(reminder.dueAt.timeIntervalSince(now)))))"
        case .dueNow:
            return "\(reminder.title)  •  starting now"
        case .overdue:
            return "\(reminder.title)  •  late by \(clockString(for: max(0, Int(now.timeIntervalSince(reminder.dueAt)))))"
        }
    }

    private var stripHeight: CGFloat {
        phase == .dueNow ? 96 : 72
    }

    private var stripFill: LinearGradient {
        switch phase {
        case .countdown:
            return LinearGradient(colors: [Color.yellow, Color.orange.opacity(0.9)], startPoint: .leading, endPoint: .trailing)
        case .dueNow:
            return LinearGradient(colors: [Color.red, Color.pink.opacity(0.85)], startPoint: .leading, endPoint: .trailing)
        case .overdue:
            return LinearGradient(colors: [Color.orange, Color.red.opacity(0.85)], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var textColor: Color {
        phase == .countdown ? .black : .white
    }

    private var labelFont: Font {
        .system(size: phase == .dueNow ? 34 : 28, weight: .black, design: .rounded)
    }

    private var labelWidth: CGFloat {
        let size = phase == .dueNow ? 34.0 : 28.0
        let font = NSFont.systemFont(ofSize: size, weight: .black)
        return NSString(string: tickerMessage.uppercased()).size(withAttributes: [.font: font]).width
    }

    private var marqueeGap: CGFloat { 56 }

    private var marqueeSpeed: Double {
        phase == .dueNow ? 240 : 150
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                Rectangle()
                    .fill(stripFill)
                    .frame(height: stripHeight)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(.white.opacity(0.18))
                            .frame(height: 1)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 18, y: 6)

                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    let cycleWidth = max(labelWidth + marqueeGap, 1)
                    let distance = (context.date.timeIntervalSince(tickerStart) * marqueeSpeed)
                        .truncatingRemainder(dividingBy: cycleWidth)

                    HStack(spacing: marqueeGap) {
                        marqueeLabel
                        marqueeLabel
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: geometry.size.width - distance)
                }
                .clipped()

                if showControls {
                    HStack(spacing: 8) {
                        Button("Snooze 5m") { onSnooze(5) }
                        Button("Snooze 10m") { onSnooze(10) }
                        Button("Dismiss") { onDismiss() }
                            .keyboardShortcut(.return)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black.opacity(0.75))
                    .padding(10)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.trailing, 18)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: stripHeight, maxHeight: stripHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            revealControls()
        }
        .onExitCommand {
            showControls = false
        }
        .onDisappear {
            hideControlsTask?.cancel()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
        .onChange(of: reminder.id) { _, _ in
            tickerStart = Date()
        }
    }

    private func revealControls() {
        hideControlsTask?.cancel()
        showControls = true

        hideControlsTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            showControls = false
        }
    }

    private var marqueeLabel: some View {
        Text(tickerMessage.uppercased())
            .font(labelFont)
            .monospacedDigit()
            .foregroundStyle(textColor)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    private func clockString(for totalSeconds: Int) -> String {
        String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
