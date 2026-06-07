import SwiftUI

struct ReminderListView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notiyf")
                .font(.largeTitle.bold())

            Text("Reminder management will appear here.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }
}
