import XCTest
@testable import Notiyf

final class ReminderTests: XCTestCase {
    func testNewReminderDefaultsToScheduled() {
        let dueAt = Date(timeIntervalSince1970: 1_800)
        let reminder = Reminder(title: "CEO Sync", dueAt: dueAt)

        XCTAssertEqual(reminder.title, "CEO Sync")
        XCTAssertEqual(reminder.dueAt, dueAt)
        XCTAssertEqual(reminder.status, .scheduled)
        XCTAssertEqual(reminder.snoozeCount, 0)
        XCTAssertNil(reminder.lastFiredAt)
    }

    func testDisplayPhaseIsCountdownBeforeDueTime() {
        let dueAt = Date(timeIntervalSince1970: 1_000)
        let now = Date(timeIntervalSince1970: 940)

        XCTAssertEqual(ReminderDisplayPhase.phase(for: dueAt, now: now), .countdown)
    }

    func testDisplayPhaseIsDueNowForFirstTenSeconds() {
        let dueAt = Date(timeIntervalSince1970: 1_000)
        let now = Date(timeIntervalSince1970: 1_009)

        XCTAssertEqual(ReminderDisplayPhase.phase(for: dueAt, now: now), .dueNow)
    }

    func testDisplayPhaseIsOverdueAfterTenSeconds() {
        let dueAt = Date(timeIntervalSince1970: 1_000)
        let now = Date(timeIntervalSince1970: 1_011)

        XCTAssertEqual(ReminderDisplayPhase.phase(for: dueAt, now: now), .overdue)
    }
}
