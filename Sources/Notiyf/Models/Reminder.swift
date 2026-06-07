import Foundation

enum ReminderStatus: String, Codable, CaseIterable, Equatable {
    case scheduled
    case active
    case snoozed
    case dismissed
    case missed
}

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var dueAt: Date
    var status: ReminderStatus
    var createdAt: Date
    var updatedAt: Date
    var lastFiredAt: Date?
    var snoozeCount: Int

    init(
        id: UUID = UUID(),
        title: String,
        dueAt: Date,
        status: ReminderStatus = .scheduled,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastFiredAt: Date? = nil,
        snoozeCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.dueAt = dueAt
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastFiredAt = lastFiredAt
        self.snoozeCount = snoozeCount
    }
}
