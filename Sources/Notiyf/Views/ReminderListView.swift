import SwiftUI

struct ReminderListView: View {
    let controller: AppController
    @State private var selection: Reminder.ID?

    private var groupedReminders: [(String, [Reminder])] {
        [
            ("Upcoming", controller.store.reminders.filter { $0.status == .scheduled }),
            ("Snoozed", controller.store.reminders.filter { $0.status == .snoozed }),
            ("Missed", controller.store.reminders.filter { $0.status == .missed }),
            ("Dismissed", controller.store.reminders.filter { $0.status == .dismissed })
        ]
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Quick Add") {
                    ReminderEditorView { title, dueAt in
                        controller.createReminder(title: title, dueAt: dueAt)
                    }
                }

                ForEach(groupedReminders, id: \.0) { group in
                    Section(group.0) {
                        ForEach(group.1) { reminder in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reminder.title)
                                    .font(.headline)

                                Text(DateFormatting.reminderDateTime.string(from: reminder.dueAt))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .contextMenu {
                                Button("Snooze 5 Minutes") {
                                    controller.snooze(reminder, minutes: 5)
                                }

                                Button("Dismiss") {
                                    controller.dismiss(reminder)
                                }

                                Divider()

                                Button("Delete", role: .destructive) {
                                    controller.delete(reminder)
                                }
                            }
                            .tag(reminder.id)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        } detail: {
            if let id = selection,
               let reminder = controller.store.reminders.first(where: { $0.id == id }) {
                ReminderEditView(
                    reminder: reminder,
                    onSave: { title, dueAt in
                        controller.update(reminder, title: title, dueAt: dueAt)
                    },
                    onDelete: {
                        controller.delete(reminder)
                        selection = nil
                    }
                )
                .id(reminder.id)
            } else {
                ContentUnavailableView("Select or create a reminder", systemImage: "bell.badge")
            }
        }
    }
}
