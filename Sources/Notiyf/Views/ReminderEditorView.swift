import SwiftUI

struct ReminderEditorView: View {
    @State private var title = ""
    @State private var dueAt = Date().addingTimeInterval(60 * 5)

    let onCreate: (String, Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Reminder title", text: $title)
                .textFieldStyle(.roundedBorder)

            DatePicker("Due", selection: $dueAt, displayedComponents: [.date, .hourAndMinute])

            Button("Add Reminder") {
                let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                onCreate(trimmed, dueAt)
                title = ""
                dueAt = Date().addingTimeInterval(60 * 5)
            }
            .keyboardShortcut(.return)
        }
    }
}
