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
    @State private var controller = AppController()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup("Notiyf", id: "reminders") {
            ReminderListView(controller: controller)
                .frame(minWidth: 760, minHeight: 460)
        }

        MenuBarExtra("Notiyf", systemImage: "bell.badge") {
            MenuBarContentView(controller: controller) {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "reminders")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
