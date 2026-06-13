import AppKit
import SwiftUI

/// Borderless overlay window that can become key so the SwiftUI marquee can
/// receive clicks (tap-to-reveal, snooze, dismiss). `.nonactivatingPanel` lets
/// it take key on click without activating Notiyf and stealing app focus.
final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

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
            let window = OverlayPanel(
                contentRect: frame,
                styleMask: [.borderless, .nonactivatingPanel],
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

struct MarqueeOverlayCopy {
    let marqueeText: String
    let statusText: String

    static func make(reminder: Reminder, now: Date) -> MarqueeOverlayCopy {
        let phase = ReminderDisplayPhase.phase(for: reminder.dueAt, now: now)
        let title = reminder.title.uppercased()

        switch phase {
        case .countdown:
            return MarqueeOverlayCopy(
                marqueeText: "\(title)  •  STARTS SOON",
                statusText: clockString(for: max(0, Int(reminder.dueAt.timeIntervalSince(now))))
            )
        case .dueNow:
            return MarqueeOverlayCopy(
                marqueeText: "\(title)  •  STARTING NOW",
                statusText: "NOW"
            )
        case .overdue:
            return MarqueeOverlayCopy(
                marqueeText: "\(title)  •  OVERDUE",
                statusText: "+\(clockString(for: max(0, Int(now.timeIntervalSince(reminder.dueAt)))))"
            )
        }
    }

    private static func clockString(for totalSeconds: Int) -> String {
        String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}

enum MarqueeTrackLayout {
    static func tileCount(containerWidth: CGFloat, tileWidth: CGFloat) -> Int {
        guard tileWidth > 0 else { return 2 }
        return max(Int(ceil(containerWidth / tileWidth)) + 2, 2)
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

    private var copy: MarqueeOverlayCopy {
        MarqueeOverlayCopy.make(reminder: reminder, now: now)
    }

    private var tickerMessage: String {
        copy.marqueeText
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
        .system(size: phase == .dueNow ? 32 : 27, weight: .black, design: .monospaced)
    }

    private var labelWidth: CGFloat {
        let size = phase == .dueNow ? 32.0 : 27.0
        let font = NSFont.monospacedSystemFont(ofSize: size, weight: .black)
        return NSString(string: tickerMessage).size(withAttributes: [.font: font]).width
    }

    private var tileWidth: CGFloat {
        max(labelWidth, 1)
    }

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
                    let cycleWidth = tileWidth
                    let distance = (context.date.timeIntervalSince(tickerStart) * marqueeSpeed)
                        .truncatingRemainder(dividingBy: cycleWidth)
                    let tileCount = MarqueeTrackLayout.tileCount(
                        containerWidth: geometry.size.width + 176,
                        tileWidth: tileWidth
                    )

                    HStack(spacing: 0) {
                        ForEach(0..<tileCount, id: \.self) { _ in
                            marqueeLabel
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: -distance)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.trailing, 176)
                .clipped()

                statusBadge
                    .padding(.trailing, showControls ? 214 : 18)

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
        Text(tickerMessage)
            .font(labelFont)
            .foregroundStyle(textColor)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.trailing, 32)
    }

    private var statusBadge: some View {
        Text(copy.statusText)
            .font(.system(size: phase == .dueNow ? 28 : 22, weight: .black, design: .monospaced))
            .foregroundStyle(textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.2), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .padding(.vertical, 12)
    }
}
