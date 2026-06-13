import Foundation

/// Groups reminders into the management window's sections, in display order.
/// Active reminders surface first so a reminder that is currently firing on the
/// marquee stays visible and manageable from the list.
enum ReminderGrouping {
    static func groups(from reminders: [Reminder]) -> [(String, [Reminder])] {
        [
            ("Active", reminders.filter { $0.status == .active }),
            ("Upcoming", reminders.filter { $0.status == .scheduled }),
            ("Snoozed", reminders.filter { $0.status == .snoozed }),
            ("Missed", reminders.filter { $0.status == .missed }),
            ("Dismissed", reminders.filter { $0.status == .dismissed })
        ]
    }
}
