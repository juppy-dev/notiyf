import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct NotiyfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Notiyf", id: "reminders") {
            ReminderListView()
                .frame(minWidth: 760, minHeight: 460)
        }

        MenuBarExtra("Notiyf", systemImage: "bell.badge") {
            Button("Manage Reminders") {
                NSApp.activate(ignoringOtherApps: true)
            }

            Divider()

            Button("Quit Notiyf") {
                NSApp.terminate(nil)
            }
        }
    }
}
