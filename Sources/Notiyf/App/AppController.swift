import Foundation
import Observation

@MainActor
@Observable
final class AppController {
    let store: ReminderStore
    let scheduler: ReminderScheduler
    private let overlayPresenter: MarqueeOverlayPresenter

    init() {
        do {
            let store = try ReminderStore()
            let scheduler = ReminderScheduler(store: store)
            let overlayPresenter = MarqueeOverlayPresenter()

            self.store = store
            self.scheduler = scheduler
            self.overlayPresenter = overlayPresenter

            scheduler.onReminderActivated = { [weak overlayPresenter] reminder in
                overlayPresenter?.show(reminder: reminder)
            }

            overlayPresenter.onSnooze = { [weak store] id, minutes in
                try? store?.snooze(id: id, minutes: minutes)
            }

            overlayPresenter.onDismiss = { [weak store] id in
                try? store?.dismiss(id: id)
            }

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
