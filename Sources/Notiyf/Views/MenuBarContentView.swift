import AppKit
import SwiftUI

struct MenuBarContentView: View {
    let controller: AppController
    let openReminders: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReminderEditorView { title, dueAt in
                controller.createReminder(title: title, dueAt: dueAt)
            }
            .frame(width: 280)

            Divider()

            Button("Manage Reminders") {
                openReminders()
            }

            Button("Quit Notiyf") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
    }
}
