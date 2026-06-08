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

    func testOverlayScreenPlacementFallsBackToPointerScreenWhenMainScreenIsMissing() {
        let left = CGRect(x: 0, y: 0, width: 1_440, height: 900)
        let right = CGRect(x: 1_440, y: 0, width: 1_440, height: 900)

        let result = OverlayScreenPlacement.frame(
            mainFrame: nil,
            candidateFrames: [left, right],
            pointerLocation: CGPoint(x: 2_000, y: 450)
        )

        XCTAssertEqual(result, right)
    }

    func testOverlayScreenPlacementFallsBackToFirstScreenWhenPointerIsOutsideAllScreens() {
        let first = CGRect(x: 0, y: 0, width: 1_440, height: 900)
        let second = CGRect(x: 1_440, y: 0, width: 1_440, height: 900)

        let result = OverlayScreenPlacement.frame(
            mainFrame: nil,
            candidateFrames: [first, second],
            pointerLocation: CGPoint(x: -50, y: -50)
        )

        XCTAssertEqual(result, first)
    }
}
