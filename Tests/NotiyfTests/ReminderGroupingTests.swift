import XCTest
@testable import Notiyf

final class ReminderGroupingTests: XCTestCase {
    func testActiveRemindersSurfaceFirstInTheirOwnGroup() {
        let due = Date(timeIntervalSince1970: 1_000)
        let active = Reminder(title: "Live", dueAt: due, status: .active)
        let upcoming = Reminder(title: "Soon", dueAt: due, status: .scheduled)

        let groups = ReminderGrouping.groups(from: [upcoming, active])

        XCTAssertEqual(groups.first?.0, "Active")
        XCTAssertEqual(groups.first?.1.map(\.id), [active.id])
    }

    func testEachStatusIsPlacedInItsMatchingGroup() {
        let due = Date(timeIntervalSince1970: 1_000)
        let reminders = [
            Reminder(title: "a", dueAt: due, status: .active),
            Reminder(title: "s", dueAt: due, status: .scheduled),
            Reminder(title: "z", dueAt: due, status: .snoozed),
            Reminder(title: "m", dueAt: due, status: .missed),
            Reminder(title: "d", dueAt: due, status: .dismissed)
        ]

        let groups = ReminderGrouping.groups(from: reminders)

        XCTAssertEqual(groups.map(\.0), ["Active", "Upcoming", "Snoozed", "Missed", "Dismissed"])
        XCTAssertEqual(groups.map { $0.1.count }, [1, 1, 1, 1, 1])
    }
}
