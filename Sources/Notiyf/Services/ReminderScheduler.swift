import Foundation

@MainActor
final class ReminderScheduler {
    private let store: ReminderStore
    private var timer: Timer?
    var onReminderActivated: ((Reminder) -> Void)?

    init(store: ReminderStore) {
        self.store = store
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                try? self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func recoverOnLaunch(now: Date = Date()) throws {
        for reminder in store.reminders {
            guard reminder.status == .scheduled || reminder.status == .snoozed else {
                continue
            }

            guard reminder.dueAt <= now else {
                continue
            }

            let overdueSeconds = now.timeIntervalSince(reminder.dueAt)
            if overdueSeconds <= 60 * 30 {
                try activate(reminder, now: now)
            } else {
                try store.markMissed(id: reminder.id, now: now)
            }
        }
    }

    func tick(now: Date = Date()) throws {
        guard let next = store.reminders
            .filter({ ($0.status == .scheduled || $0.status == .snoozed) && $0.dueAt <= now })
            .sorted(by: { $0.dueAt < $1.dueAt })
            .first else {
            return
        }

        try activate(next, now: now)
    }

    private func activate(_ reminder: Reminder, now: Date) throws {
        try store.activate(id: reminder.id, now: now)

        if let active = store.reminders.first(where: { $0.id == reminder.id }) {
            onReminderActivated?(active)
        }
    }
}
