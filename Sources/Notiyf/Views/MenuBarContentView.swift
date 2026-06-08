import AppKit
import SwiftUI

struct MenuBarContentView: View {
    let controller: AppController
    let openReminders: () -> Void

    private var pendingReminderCount: Int {
        controller.store.reminders.filter { $0.status != .dismissed }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notiyf")
                    .font(.title3.weight(.semibold))

                Text(pendingReminderCount == 0 ? "A rude little backup for your future self." : "\(pendingReminderCount) active reminders waiting to bother you.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ReminderEditorView { title, dueAt in
                controller.createReminder(title: title, dueAt: dueAt)
            }
            .frame(width: 280)
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Divider()

            Button(action: openReminders) {
                Label("Manage Reminders", systemImage: "list.bullet.rectangle")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)

#if DEBUG
            Button {
                controller.triggerTestMarquee()
            } label: {
                Label("Trigger Test Marquee", systemImage: "waveform.path.ecg.rectangle")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
#endif

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Label("Quit Notiyf", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .frame(width: 320)
    }
}
