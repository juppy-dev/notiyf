import Foundation
import Observation

enum ReminderStoreError: Error, Equatable {
    case reminderNotFound
}

@Observable
final class ReminderStore {
    private let persistence: ReminderPersisting
    private(set) var reminders: [Reminder]

    init(persistence: ReminderPersisting = JSONReminderPersistence()) throws {
        self.persistence = persistence
        self.reminders = try persistence.load()
    }

    @discardableResult
    func create(title: String, dueAt: Date, now: Date = Date()) throws -> Reminder {
        let reminder = Reminder(title: title, dueAt: dueAt, createdAt: now, updatedAt: now)
        reminders.append(reminder)
        try persist()
        return reminder
    }

    func update(id: Reminder.ID, title: String, dueAt: Date, now: Date = Date()) throws {
        try mutate(id: id) { reminder in
            reminder.title = title
            reminder.dueAt = dueAt
            reminder.status = .scheduled
            reminder.updatedAt = now
        }
    }

    func delete(id: Reminder.ID) throws {
        reminders.removeAll { $0.id == id }
        try persist()
    }

    func activate(id: Reminder.ID, now: Date = Date()) throws {
        try mutate(id: id) { reminder in
            reminder.status = .active
            reminder.lastFiredAt = now
            reminder.updatedAt = now
        }
    }

    func snooze(id: Reminder.ID, minutes: Int, now: Date = Date()) throws {
        try mutate(id: id) { reminder in
            reminder.dueAt = now.addingTimeInterval(TimeInterval(minutes * 60))
            reminder.status = .snoozed
            reminder.snoozeCount += 1
            reminder.updatedAt = now
        }
    }

    func dismiss(id: Reminder.ID, now: Date = Date()) throws {
        try mutate(id: id) { reminder in
            reminder.status = .dismissed
            reminder.updatedAt = now
        }
    }

    func markMissed(id: Reminder.ID, now: Date = Date()) throws {
        try mutate(id: id) { reminder in
            reminder.status = .missed
            reminder.updatedAt = now
        }
    }

    private func mutate(id: Reminder.ID, change: (inout Reminder) -> Void) throws {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else {
            throw ReminderStoreError.reminderNotFound
        }

        change(&reminders[index])
        try persist()
    }

    private func persist() throws {
        try persistence.save(reminders)
    }
}
