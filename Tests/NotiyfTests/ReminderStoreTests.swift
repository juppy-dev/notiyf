import XCTest
@testable import Notiyf

private final class InMemoryReminderPersistence: ReminderPersisting {
    var savedReminders: [Reminder] = []
    var remindersToLoad: [Reminder] = []

    func load() throws -> [Reminder] {
        remindersToLoad
    }

    func save(_ reminders: [Reminder]) throws {
        savedReminders = reminders
    }
}

final class ReminderStoreTests: XCTestCase {
    func testCreateReminderPersistsScheduledReminder() throws {
        let persistence = InMemoryReminderPersistence()
        let store = try ReminderStore(persistence: persistence)
        let dueAt = Date(timeIntervalSince1970: 2_000)

        let reminder = try store.create(title: "Standup", dueAt: dueAt)

        XCTAssertEqual(store.reminders.count, 1)
        XCTAssertEqual(reminder.status, .scheduled)
        XCTAssertEqual(persistence.savedReminders, store.reminders)
    }

    func testSnoozeReschedulesReminder() throws {
        let persistence = InMemoryReminderPersistence()
        let store = try ReminderStore(persistence: persistence)
        let reminder = try store.create(title: "Standup", dueAt: Date(timeIntervalSince1970: 2_000))
        let now = Date(timeIntervalSince1970: 2_000)

        try store.snooze(id: reminder.id, minutes: 10, now: now)

        let updated = try XCTUnwrap(store.reminders.first)
        XCTAssertEqual(updated.status, .snoozed)
        XCTAssertEqual(updated.dueAt, Date(timeIntervalSince1970: 2_600))
        XCTAssertEqual(updated.snoozeCount, 1)
    }

    func testUpdateRevivesReminderAndReschedules() throws {
        let persistence = InMemoryReminderPersistence()
        let store = try ReminderStore(persistence: persistence)
        let reminder = try store.create(title: "Standup", dueAt: Date(timeIntervalSince1970: 2_000))
        try store.dismiss(id: reminder.id)
        let newDue = Date(timeIntervalSince1970: 5_000)
        let now = Date(timeIntervalSince1970: 3_000)

        try store.update(id: reminder.id, title: "CEO Sync", dueAt: newDue, now: now)

        let updated = try XCTUnwrap(store.reminders.first)
        XCTAssertEqual(updated.title, "CEO Sync")
        XCTAssertEqual(updated.dueAt, newDue)
        XCTAssertEqual(updated.status, .scheduled)
        XCTAssertEqual(updated.updatedAt, now)
        XCTAssertEqual(persistence.savedReminders, store.reminders)
    }

    func testDismissMarksReminderDismissed() throws {
        let persistence = InMemoryReminderPersistence()
        let store = try ReminderStore(persistence: persistence)
        let reminder = try store.create(title: "Standup", dueAt: Date(timeIntervalSince1970: 2_000))

        try store.dismiss(id: reminder.id)

        XCTAssertEqual(store.reminders.first?.status, .dismissed)
    }

    func testDeleteMissingReminderThrows() throws {
        let persistence = InMemoryReminderPersistence()
        let store = try ReminderStore(persistence: persistence)

        XCTAssertThrowsError(try store.delete(id: UUID())) { error in
            XCTAssertEqual(error as? ReminderStoreError, .reminderNotFound)
        }
        XCTAssertEqual(persistence.savedReminders, [])
    }
}
