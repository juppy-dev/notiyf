import XCTest
@testable import Notiyf

private final class SchedulerPersistence: ReminderPersisting {
    var reminders: [Reminder]

    init(reminders: [Reminder]) {
        self.reminders = reminders
    }

    func load() throws -> [Reminder] {
        reminders
    }

    func save(_ reminders: [Reminder]) throws {
        self.reminders = reminders
    }
}

@MainActor
final class ReminderSchedulerTests: XCTestCase {
    func testDueReminderActivates() throws {
        let due = Reminder(title: "Standup", dueAt: Date(timeIntervalSince1970: 1_000))
        let store = try ReminderStore(persistence: SchedulerPersistence(reminders: [due]))
        let scheduler = ReminderScheduler(store: store)

        try scheduler.tick(now: Date(timeIntervalSince1970: 1_000))

        XCTAssertEqual(store.reminders.first?.status, .active)
    }

    func testRecentOverdueReminderActivatesOnLaunch() throws {
        let reminder = Reminder(title: "Standup", dueAt: Date(timeIntervalSince1970: 1_000))
        let store = try ReminderStore(persistence: SchedulerPersistence(reminders: [reminder]))
        let scheduler = ReminderScheduler(store: store)

        try scheduler.recoverOnLaunch(now: Date(timeIntervalSince1970: 1_000 + 60 * 20))

        XCTAssertEqual(store.reminders.first?.status, .active)
    }

    func testOldOverdueReminderBecomesMissedOnLaunch() throws {
        let reminder = Reminder(title: "Standup", dueAt: Date(timeIntervalSince1970: 1_000))
        let store = try ReminderStore(persistence: SchedulerPersistence(reminders: [reminder]))
        let scheduler = ReminderScheduler(store: store)

        try scheduler.recoverOnLaunch(now: Date(timeIntervalSince1970: 1_000 + 60 * 31))

        XCTAssertEqual(store.reminders.first?.status, .missed)
    }
}
