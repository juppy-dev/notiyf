import SwiftUI

struct ReminderEditView: View {
    let reminder: Reminder
    let onSave: (String, Date) -> Void
    let onDelete: () -> Void

    @State private var title: String
    @State private var dueAt: Date

    init(
        reminder: Reminder,
        onSave: @escaping (String, Date) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.reminder = reminder
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: reminder.title)
        _dueAt = State(initialValue: reminder.dueAt)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Reminder")
                .font(.headline)

            TextField("What can't you miss?", text: $title)
                .textFieldStyle(.roundedBorder)

            DatePicker("Alert me at", selection: $dueAt, displayedComponents: [.date, .hourAndMinute])

            HStack {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Spacer()

                Button {
                    guard !trimmedTitle.isEmpty else { return }
                    onSave(trimmedTitle, dueAt)
                } label: {
                    Label("Save", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
                .disabled(trimmedTitle.isEmpty)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
