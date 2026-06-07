import Foundation

enum ReminderDisplayPhase: Equatable {
    case countdown
    case dueNow
    case overdue

    static func phase(for dueAt: Date, now: Date = Date()) -> ReminderDisplayPhase {
        if now < dueAt {
            return .countdown
        }

        if now.timeIntervalSince(dueAt) <= 10 {
            return .dueNow
        }

        return .overdue
    }
}
