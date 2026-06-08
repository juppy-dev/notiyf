import SwiftUI

struct ReminderEditorView: View {
    @State private var title = ""
    @State private var dueAt = Date().addingTimeInterval(60 * 5)

    let onCreate: (String, Date) -> Void

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.headline)

            Text("Make the next important thing harder to ignore.")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("What can't you miss?", text: $title)
                .textFieldStyle(.roundedBorder)

            DatePicker("Alert me at", selection: $dueAt, displayedComponents: [.date, .hourAndMinute])

            Button {
                guard !trimmedTitle.isEmpty else { return }
                onCreate(trimmedTitle, dueAt)
                title = ""
                dueAt = Date().addingTimeInterval(60 * 5)
            } label: {
                Label("Create Reminder", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return)
            .disabled(trimmedTitle.isEmpty)
        }
    }
}
