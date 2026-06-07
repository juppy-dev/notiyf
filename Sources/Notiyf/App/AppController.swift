import Foundation
import Observation

@MainActor
@Observable
final class AppController {
    let store: ReminderStore
    let scheduler: ReminderScheduler

    init() {
        do {
            let store = try ReminderStore()
            self.store = store
            self.scheduler = ReminderScheduler(store: store)
            try scheduler.recoverOnLaunch()
            scheduler.start()
        } catch {
            fatalError("Failed to start Notiyf: \(error)")
        }
    }

    func createReminder(title: String, dueAt: Date) {
        _ = try? store.create(title: title, dueAt: dueAt)
    }

    func delete(_ reminder: Reminder) {
        try? store.delete(id: reminder.id)
    }

    func dismiss(_ reminder: Reminder) {
        try? store.dismiss(id: reminder.id)
    }

    func snooze(_ reminder: Reminder, minutes: Int) {
        try? store.snooze(id: reminder.id, minutes: minutes)
    }
}
