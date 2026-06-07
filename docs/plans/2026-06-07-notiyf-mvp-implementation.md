# Notiyf MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Notiyf macOS MVP: manual reminders, menu bar quick-add, management window, local JSON persistence, scheduling, and a persistent marquee overlay with click-to-reveal snooze/dismiss controls.

**Architecture:** Use a SwiftPM SwiftUI macOS GUI app. SwiftUI owns the app shell, menu bar extra, reminder list, forms, and app state; AppKit is used only for the always-on-top marquee overlay window. Core reminder logic lives in small model/store/scheduler types with unit tests before UI integration.

**Tech Stack:** Swift 5.9+, SwiftPM, SwiftUI, AppKit, XCTest, Foundation JSON persistence.

---

## Scope Check

This plan implements the approved MVP spec in `docs/specs/2026-06-07-notiyf-mvp-design.md`.

Included:

- SwiftPM macOS app scaffold.
- Codex Run button bootstrap.
- CodeGraph initialization after initial Swift files exist.
- Reminder model and pure scheduling logic.
- JSON persistence in Application Support.
- SwiftUI menu bar, quick-add, and management window.
- AppKit marquee overlay presenter.
- Unit tests for model, store, scheduler, launch recovery, snooze, dismiss, and display phase.

Deferred:

- Calendar integration.
- Recurring reminders.
- Alternate airplane/bird/bee presenters.
- Heavy preferences.
- UI automation for global overlay behavior.

## File Structure

Create:

- `Package.swift`: SwiftPM package definition for app and tests.
- `.codex/environments/environment.toml`: Codex Run action.
- `script/build_and_run.sh`: single build/run/verify/log script for the SwiftPM GUI app bundle.
- `Sources/Notiyf/App/NotiyfApp.swift`: app entrypoint, app delegate, scene definitions.
- `Sources/Notiyf/App/AppController.swift`: app-wide object that wires store, scheduler, and overlay presenter.
- `Sources/Notiyf/Models/Reminder.swift`: reminder value model, status enum, edit payload.
- `Sources/Notiyf/Models/ReminderDisplayPhase.swift`: countdown/due-now/overdue phase logic.
- `Sources/Notiyf/Stores/ReminderStore.swift`: observable in-memory reminder store and state transitions.
- `Sources/Notiyf/Stores/ReminderPersistence.swift`: JSON load/save protocol and Application Support implementation.
- `Sources/Notiyf/Services/ReminderScheduler.swift`: timer-driven scheduling and launch recovery.
- `Sources/Notiyf/Services/MarqueeOverlayPresenter.swift`: AppKit always-on-top overlay window and action callbacks.
- `Sources/Notiyf/Views/ReminderListView.swift`: management window.
- `Sources/Notiyf/Views/ReminderEditorView.swift`: reusable create/edit form.
- `Sources/Notiyf/Views/MenuBarContentView.swift`: menu bar extra content and quick-add access.
- `Sources/Notiyf/Support/DateFormatting.swift`: small date display helpers.
- `Tests/NotiyfTests/ReminderTests.swift`: model and display phase tests.
- `Tests/NotiyfTests/ReminderStoreTests.swift`: store transition tests.
- `Tests/NotiyfTests/ReminderSchedulerTests.swift`: scheduling and launch recovery tests.

Generated/untracked:

- `dist/`: generated app bundle from `script/build_and_run.sh`.
- `.build/`: SwiftPM build output.

Modify:

- `.gitignore`: add `.build/` and `dist/`.

## Task 1: Scaffold SwiftPM macOS App

**Files:**

- Create: `Package.swift`
- Create: `Sources/Notiyf/App/NotiyfApp.swift`
- Create: `Sources/Notiyf/Views/ReminderListView.swift`
- Modify: `.gitignore`

- [ ] **Step 1: Create the SwiftPM package file**

Create `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Notiyf",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Notiyf", targets: ["Notiyf"])
    ],
    targets: [
        .executableTarget(
            name: "Notiyf",
            path: "Sources/Notiyf"
        ),
        .testTarget(
            name: "NotiyfTests",
            dependencies: ["Notiyf"],
            path: "Tests/NotiyfTests"
        )
    ]
)
```

- [ ] **Step 2: Create the initial app entrypoint**

Create `Sources/Notiyf/App/NotiyfApp.swift`:

```swift
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
```

- [ ] **Step 3: Create a temporary root view**

Create `Sources/Notiyf/Views/ReminderListView.swift`:

```swift
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
```

- [ ] **Step 4: Ignore generated build artifacts**

Update `.gitignore` to:

```gitignore
.superpowers/
.build/
dist/
```

- [ ] **Step 5: Build the empty app**

Run:

```bash
swift build
```

Expected: `Build complete!`

- [ ] **Step 6: Commit**

Run:

```bash
git add .gitignore Package.swift Sources/Notiyf/App/NotiyfApp.swift Sources/Notiyf/Views/ReminderListView.swift
git commit -m "chore(app): scaffold SwiftPM macOS app"
```

## Task 2: Add Run Script, Codex Run Action, And CodeGraph

**Files:**

- Create: `script/build_and_run.sh`
- Create: `.codex/environments/environment.toml`

- [ ] **Step 1: Create the build-and-run script**

Create `script/build_and_run.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Notiyf"
BUNDLE_ID="com.notiyf.Notiyf"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
```

- [ ] **Step 2: Make the script executable**

Run:

```bash
chmod +x script/build_and_run.sh
```

Expected: no output.

- [ ] **Step 3: Add the Codex environment action**

Create `.codex/environments/environment.toml`:

```toml
# THIS IS AUTOGENERATED. DO NOT EDIT MANUALLY
version = 1
name = "Notiyf"

[setup]
script = ""

[[actions]]
name = "Run"
icon = "run"
command = "./script/build_and_run.sh"
```

- [ ] **Step 4: Verify the script builds and launches**

Run:

```bash
./script/build_and_run.sh --verify
```

Expected: Swift build succeeds and `pgrep -x Notiyf` succeeds.

- [ ] **Step 5: Initialize CodeGraph after scaffold exists**

Run:

```bash
codegraph init -i
```

Expected: CodeGraph initializes and indexes the Swift project files.

- [ ] **Step 6: Commit**

Run:

```bash
git add script/build_and_run.sh .codex/environments/environment.toml
git commit -m "chore(app): add macOS run workflow"
```

## Task 3: Implement Reminder Model And Display Phase

**Files:**

- Create: `Sources/Notiyf/Models/Reminder.swift`
- Create: `Sources/Notiyf/Models/ReminderDisplayPhase.swift`
- Create: `Tests/NotiyfTests/ReminderTests.swift`

- [ ] **Step 1: Write failing model and phase tests**

Create `Tests/NotiyfTests/ReminderTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
swift test --filter ReminderTests
```

Expected: FAIL because `Reminder` and `ReminderDisplayPhase` do not exist.

- [ ] **Step 3: Implement the reminder model**

Create `Sources/Notiyf/Models/Reminder.swift`:

```swift
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
```

- [ ] **Step 4: Implement display phase calculation**

Create `Sources/Notiyf/Models/ReminderDisplayPhase.swift`:

```swift
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
```

- [ ] **Step 5: Run tests and verify pass**

Run:

```bash
swift test --filter ReminderTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

Run:

```bash
git add Sources/Notiyf/Models/Reminder.swift Sources/Notiyf/Models/ReminderDisplayPhase.swift Tests/NotiyfTests/ReminderTests.swift
git commit -m "feat(model): add reminder state model"
```

## Task 4: Implement Store And JSON Persistence

**Files:**

- Create: `Sources/Notiyf/Stores/ReminderPersistence.swift`
- Create: `Sources/Notiyf/Stores/ReminderStore.swift`
- Create: `Tests/NotiyfTests/ReminderStoreTests.swift`

- [ ] **Step 1: Write failing store tests**

Create `Tests/NotiyfTests/ReminderStoreTests.swift`:

```swift
import XCTest
@testable import Notiyf

private final class InMemoryReminderPersistence: ReminderPersisting {
    var savedReminders: [Reminder] = []
    var remindersToLoad: [Reminder] = []

    func load() throws -> [Reminder] {
        remindersToLoad
    }

    func save(_ reminders: [Reminder]) throws {
        savedReminders = reminders
    }
}

final class ReminderStoreTests: XCTestCase {
    func testCreateReminderPersistsScheduledReminder() throws {
        let persistence = InMemoryReminderPersistence()
        let store = try ReminderStore(persistence: persistence)
        let dueAt = Date(timeIntervalSince1970: 2_000)

        let reminder = try store.create(title: "Standup", dueAt: dueAt)

        XCTAssertEqual(store.reminders.count, 1)
        XCTAssertEqual(reminder.status, .scheduled)
        XCTAssertEqual(persistence.savedReminders, store.reminders)
    }

    func testSnoozeReschedulesReminder() throws {
        let persistence = InMemoryReminderPersistence()
        let store = try ReminderStore(persistence: persistence)
        let reminder = try store.create(title: "Standup", dueAt: Date(timeIntervalSince1970: 2_000))
        let now = Date(timeIntervalSince1970: 2_000)

        try store.snooze(id: reminder.id, minutes: 10, now: now)

        let updated = try XCTUnwrap(store.reminders.first)
        XCTAssertEqual(updated.status, .snoozed)
        XCTAssertEqual(updated.dueAt, Date(timeIntervalSince1970: 2_600))
        XCTAssertEqual(updated.snoozeCount, 1)
    }

    func testDismissMarksReminderDismissed() throws {
        let persistence = InMemoryReminderPersistence()
        let store = try ReminderStore(persistence: persistence)
        let reminder = try store.create(title: "Standup", dueAt: Date(timeIntervalSince1970: 2_000))

        try store.dismiss(id: reminder.id)

        XCTAssertEqual(store.reminders.first?.status, .dismissed)
    }
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
swift test --filter ReminderStoreTests
```

Expected: FAIL because `ReminderStore` and `ReminderPersisting` do not exist.

- [ ] **Step 3: Implement persistence protocol and JSON persistence**

Create `Sources/Notiyf/Stores/ReminderPersistence.swift`:

```swift
import Foundation

protocol ReminderPersisting {
    func load() throws -> [Reminder]
    func save(_ reminders: [Reminder]) throws
}

final class JSONReminderPersistence: ReminderPersisting {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL = JSONReminderPersistence.defaultFileURL()) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func load() throws -> [Reminder] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([Reminder].self, from: data)
    }

    func save(_ reminders: [Reminder]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(reminders)
        try data.write(to: fileURL, options: .atomic)
    }

    static func defaultFileURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appending(path: "Notiyf/reminders.json")
    }
}
```

- [ ] **Step 4: Implement reminder store**

Create `Sources/Notiyf/Stores/ReminderStore.swift`:

```swift
import Foundation
import Observation

enum ReminderStoreError: Error, Equatable {
    case reminderNotFound
}

@Observable
final class ReminderStore {
    private let persistence: ReminderPersisting
    private(set) var reminders: [Reminder]

    init(persistence: ReminderPersisting = JSONReminderPersistence()) throws {
        self.persistence = persistence
        self.reminders = try persistence.load()
    }

    @discardableResult
    func create(title: String, dueAt: Date, now: Date = Date()) throws -> Reminder {
        let reminder = Reminder(title: title, dueAt: dueAt, createdAt: now, updatedAt: now)
        reminders.append(reminder)
        try persist()
        return reminder
    }

    func update(id: Reminder.ID, title: String, dueAt: Date, now: Date = Date()) throws {
        try mutate(id: id) { reminder in
            reminder.title = title
            reminder.dueAt = dueAt
            reminder.status = .scheduled
            reminder.updatedAt = now
        }
    }

    func delete(id: Reminder.ID) throws {
        reminders.removeAll { $0.id == id }
        try persist()
    }

    func activate(id: Reminder.ID, now: Date = Date()) throws {
        try mutate(id: id) { reminder in
            reminder.status = .active
            reminder.lastFiredAt = now
            reminder.updatedAt = now
        }
    }

    func snooze(id: Reminder.ID, minutes: Int, now: Date = Date()) throws {
        try mutate(id: id) { reminder in
            reminder.dueAt = now.addingTimeInterval(TimeInterval(minutes * 60))
            reminder.status = .snoozed
            reminder.snoozeCount += 1
            reminder.updatedAt = now
        }
    }

    func dismiss(id: Reminder.ID, now: Date = Date()) throws {
        try mutate(id: id) { reminder in
            reminder.status = .dismissed
            reminder.updatedAt = now
        }
    }

    func markMissed(id: Reminder.ID, now: Date = Date()) throws {
        try mutate(id: id) { reminder in
            reminder.status = .missed
            reminder.updatedAt = now
        }
    }

    private func mutate(id: Reminder.ID, change: (inout Reminder) -> Void) throws {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else {
            throw ReminderStoreError.reminderNotFound
        }

        change(&reminders[index])
        try persist()
    }

    private func persist() throws {
        try persistence.save(reminders)
    }
}
```

- [ ] **Step 5: Run store tests**

Run:

```bash
swift test --filter ReminderStoreTests
```

Expected: PASS.

- [ ] **Step 6: Run all tests**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 7: Commit**

Run:

```bash
git add Sources/Notiyf/Stores/ReminderPersistence.swift Sources/Notiyf/Stores/ReminderStore.swift Tests/NotiyfTests/ReminderStoreTests.swift
git commit -m "feat(store): persist manual reminders"
```

## Task 5: Implement Scheduler And Launch Recovery

**Files:**

- Create: `Sources/Notiyf/Services/ReminderScheduler.swift`
- Create: `Tests/NotiyfTests/ReminderSchedulerTests.swift`

- [ ] **Step 1: Write failing scheduler tests**

Create `Tests/NotiyfTests/ReminderSchedulerTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
swift test --filter ReminderSchedulerTests
```

Expected: FAIL because `ReminderScheduler` does not exist.

- [ ] **Step 3: Implement scheduler**

Create `Sources/Notiyf/Services/ReminderScheduler.swift`:

```swift
import Foundation

@MainActor
final class ReminderScheduler {
    private let store: ReminderStore
    private var timer: Timer?
    var onReminderActivated: ((Reminder) -> Void)?

    init(store: ReminderStore) {
        self.store = store
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                try? self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func recoverOnLaunch(now: Date = Date()) throws {
        for reminder in store.reminders {
            guard reminder.status == .scheduled || reminder.status == .snoozed else {
                continue
            }

            guard reminder.dueAt <= now else {
                continue
            }

            let overdueSeconds = now.timeIntervalSince(reminder.dueAt)
            if overdueSeconds <= 60 * 30 {
                try activate(reminder, now: now)
            } else {
                try store.markMissed(id: reminder.id, now: now)
            }
        }
    }

    func tick(now: Date = Date()) throws {
        guard let next = store.reminders
            .filter({ ($0.status == .scheduled || $0.status == .snoozed) && $0.dueAt <= now })
            .sorted(by: { $0.dueAt < $1.dueAt })
            .first else {
            return
        }

        try activate(next, now: now)
    }

    private func activate(_ reminder: Reminder, now: Date) throws {
        try store.activate(id: reminder.id, now: now)

        if let active = store.reminders.first(where: { $0.id == reminder.id }) {
            onReminderActivated?(active)
        }
    }
}
```

- [ ] **Step 4: Run scheduler tests**

Run:

```bash
swift test --filter ReminderSchedulerTests
```

Expected: PASS.

- [ ] **Step 5: Run all tests**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 6: Commit**

Run:

```bash
git add Sources/Notiyf/Services/ReminderScheduler.swift Tests/NotiyfTests/ReminderSchedulerTests.swift
git commit -m "feat(scheduler): activate due reminders"
```

## Task 6: Wire App Controller And SwiftUI Reminder UI

**Files:**

- Create: `Sources/Notiyf/App/AppController.swift`
- Create: `Sources/Notiyf/Views/MenuBarContentView.swift`
- Create: `Sources/Notiyf/Views/ReminderEditorView.swift`
- Create: `Sources/Notiyf/Support/DateFormatting.swift`
- Modify: `Sources/Notiyf/App/NotiyfApp.swift`
- Modify: `Sources/Notiyf/Views/ReminderListView.swift`

- [ ] **Step 1: Create app controller**

Create `Sources/Notiyf/App/AppController.swift`:

```swift
import Foundation
import Observation

@MainActor
@Observable
final class AppController {
    let store: ReminderStore
    let scheduler: ReminderScheduler

    init() {
        do {
            let store = try ReminderStore()
            self.store = store
            self.scheduler = ReminderScheduler(store: store)
            try scheduler.recoverOnLaunch()
            scheduler.start()
        } catch {
            fatalError("Failed to start Notiyf: \(error)")
        }
    }

    func createReminder(title: String, dueAt: Date) {
        try? store.create(title: title, dueAt: dueAt)
    }

    func delete(_ reminder: Reminder) {
        try? store.delete(id: reminder.id)
    }

    func dismiss(_ reminder: Reminder) {
        try? store.dismiss(id: reminder.id)
    }

    func snooze(_ reminder: Reminder, minutes: Int) {
        try? store.snooze(id: reminder.id, minutes: minutes)
    }
}
```

- [ ] **Step 2: Create date formatting helper**

Create `Sources/Notiyf/Support/DateFormatting.swift`:

```swift
import Foundation

enum DateFormatting {
    static let reminderDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
```

- [ ] **Step 3: Create reminder editor view**

Create `Sources/Notiyf/Views/ReminderEditorView.swift`:

```swift
import SwiftUI

struct ReminderEditorView: View {
    @State private var title = ""
    @State private var dueAt = Date().addingTimeInterval(60 * 5)

    let onCreate: (String, Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Reminder title", text: $title)
                .textFieldStyle(.roundedBorder)

            DatePicker("Due", selection: $dueAt, displayedComponents: [.date, .hourAndMinute])

            Button("Add Reminder") {
                let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                onCreate(trimmed, dueAt)
                title = ""
                dueAt = Date().addingTimeInterval(60 * 5)
            }
            .keyboardShortcut(.return)
        }
    }
}
```

- [ ] **Step 4: Create menu bar content**

Create `Sources/Notiyf/Views/MenuBarContentView.swift`:

```swift
import AppKit
import SwiftUI

struct MenuBarContentView: View {
    let controller: AppController
    let openReminders: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReminderEditorView { title, dueAt in
                controller.createReminder(title: title, dueAt: dueAt)
            }
            .frame(width: 280)

            Divider()

            Button("Manage Reminders") {
                openReminders()
            }

            Button("Quit Notiyf") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
    }
}
```

- [ ] **Step 5: Replace the temporary reminder list view**

Replace `Sources/Notiyf/Views/ReminderListView.swift` with:

```swift
import SwiftUI

struct ReminderListView: View {
    let controller: AppController

    private var groupedReminders: [(String, [Reminder])] {
        [
            ("Upcoming", controller.store.reminders.filter { $0.status == .scheduled }),
            ("Snoozed", controller.store.reminders.filter { $0.status == .snoozed }),
            ("Missed", controller.store.reminders.filter { $0.status == .missed }),
            ("Dismissed", controller.store.reminders.filter { $0.status == .dismissed })
        ]
    }

    var body: some View {
        NavigationSplitView {
            List {
                Section("Quick Add") {
                    ReminderEditorView { title, dueAt in
                        controller.createReminder(title: title, dueAt: dueAt)
                    }
                }

                ForEach(groupedReminders, id: \.0) { group in
                    Section(group.0) {
                        ForEach(group.1) { reminder in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reminder.title)
                                    .font(.headline)

                                Text(DateFormatting.reminderDateTime.string(from: reminder.dueAt))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .contextMenu {
                                Button("Snooze 5 Minutes") {
                                    controller.snooze(reminder, minutes: 5)
                                }

                                Button("Dismiss") {
                                    controller.dismiss(reminder)
                                }

                                Divider()

                                Button("Delete", role: .destructive) {
                                    controller.delete(reminder)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        } detail: {
            ContentUnavailableView("Select or create a reminder", systemImage: "bell.badge")
        }
    }
}
```

- [ ] **Step 6: Wire controller into app scenes**

Replace `Sources/Notiyf/App/NotiyfApp.swift` with:

```swift
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
```

- [ ] **Step 7: Build**

Run:

```bash
swift build
```

Expected: PASS.

- [ ] **Step 8: Commit**

Run:

```bash
git add Sources/Notiyf/App Sources/Notiyf/Views Sources/Notiyf/Support
git commit -m "feat(ui): add manual reminder management"
```

## Task 7: Implement AppKit Marquee Overlay

**Files:**

- Create: `Sources/Notiyf/Services/MarqueeOverlayPresenter.swift`
- Modify: `Sources/Notiyf/App/AppController.swift`

- [ ] **Step 1: Create marquee overlay presenter**

Create `Sources/Notiyf/Services/MarqueeOverlayPresenter.swift`:

```swift
import AppKit
import SwiftUI

@MainActor
final class MarqueeOverlayPresenter {
    private var window: NSWindow?
    private var hostingView: NSHostingView<MarqueeOverlayView>?
    private var reminder: Reminder?

    var onSnooze: ((Reminder.ID, Int) -> Void)?
    var onDismiss: ((Reminder.ID) -> Void)?

    func show(reminder: Reminder) {
        self.reminder = reminder

        let overlayView = MarqueeOverlayView(
            reminder: reminder,
            onSnooze: { [weak self] minutes in
                guard let id = self?.reminder?.id else { return }
                self?.hide()
                self?.onSnooze?(id, minutes)
            },
            onDismiss: { [weak self] in
                guard let id = self?.reminder?.id else { return }
                self?.hide()
                self?.onDismiss?(id)
            }
        )

        if window == nil {
            let screenFrame = NSScreen.main?.frame ?? .zero
            let frame = NSRect(x: 0, y: screenFrame.height - 120, width: screenFrame.width, height: 96)
            let window = NSWindow(
                contentRect: frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.ignoresMouseEvents = false
            self.window = window
        }

        let hostingView = NSHostingView(rootView: overlayView)
        self.hostingView = hostingView
        window?.contentView = hostingView
        window?.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
        reminder = nil
    }
}

private struct MarqueeOverlayView: View {
    let reminder: Reminder
    let onSnooze: (Int) -> Void
    let onDismiss: () -> Void

    @State private var now = Date()
    @State private var showControls = false
    @State private var textOffset: CGFloat = 900

    private var phase: ReminderDisplayPhase {
        ReminderDisplayPhase.phase(for: reminder.dueAt, now: now)
    }

    private var message: String {
        switch phase {
        case .countdown:
            let seconds = max(0, Int(reminder.dueAt.timeIntervalSince(now)))
            return "\(reminder.title) in \(seconds / 60)m \(seconds % 60)s"
        case .dueNow:
            return "\(reminder.title) is starting now"
        case .overdue:
            let seconds = max(0, Int(now.timeIntervalSince(reminder.dueAt)))
            return "\(reminder.title) started \(seconds / 60)m ago"
        }
    }

    private var stripHeight: CGFloat {
        phase == .dueNow ? 96 : 72
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Rectangle()
                .fill(phase == .dueNow ? Color.red : Color.yellow)
                .frame(height: stripHeight)
                .shadow(radius: 12)

            Text(message.uppercased() + "  -  " + message.uppercased() + "  -  ")
                .font(.system(size: phase == .dueNow ? 34 : 28, weight: .black, design: .rounded))
                .foregroundStyle(phase == .dueNow ? .white : .black)
                .lineLimit(1)
                .offset(x: textOffset)
                .onAppear {
                    animate()
                }
                .onChange(of: phase) { _, _ in
                    animate()
                }

            if showControls {
                HStack(spacing: 8) {
                    Button("Snooze 5m") { onSnooze(5) }
                    Button("Snooze 10m") { onSnooze(10) }
                    Button("Dismiss") { onDismiss() }
                        .keyboardShortcut(.return)
                }
                .padding(10)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.trailing, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            revealControls()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
    }

    private func revealControls() {
        showControls = true

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(8))
            showControls = false
        }
    }

    private func animate() {
        textOffset = 900
        withAnimation(.linear(duration: phase == .dueNow ? 2.5 : 5).repeatForever(autoreverses: false)) {
            textOffset = -900
        }
    }
}
```

- [ ] **Step 2: Wire overlay presenter to scheduler and store actions**

Replace `Sources/Notiyf/App/AppController.swift` with:

```swift
import Foundation
import Observation

@MainActor
@Observable
final class AppController {
    let store: ReminderStore
    let scheduler: ReminderScheduler
    private let overlayPresenter: MarqueeOverlayPresenter

    init() {
        do {
            let store = try ReminderStore()
            let scheduler = ReminderScheduler(store: store)
            let overlayPresenter = MarqueeOverlayPresenter()

            self.store = store
            self.scheduler = scheduler
            self.overlayPresenter = overlayPresenter

            scheduler.onReminderActivated = { [weak overlayPresenter] reminder in
                overlayPresenter?.show(reminder: reminder)
            }

            overlayPresenter.onSnooze = { [weak store] id, minutes in
                try? store?.snooze(id: id, minutes: minutes)
            }

            overlayPresenter.onDismiss = { [weak store] id in
                try? store?.dismiss(id: id)
            }

            try scheduler.recoverOnLaunch()
            scheduler.start()
        } catch {
            fatalError("Failed to start Notiyf: \(error)")
        }
    }

    func createReminder(title: String, dueAt: Date) {
        try? store.create(title: title, dueAt: dueAt)
    }

    func delete(_ reminder: Reminder) {
        try? store.delete(id: reminder.id)
    }

    func dismiss(_ reminder: Reminder) {
        try? store.dismiss(id: reminder.id)
    }

    func snooze(_ reminder: Reminder, minutes: Int) {
        try? store.snooze(id: reminder.id, minutes: minutes)
    }
}
```

- [ ] **Step 3: Build**

Run:

```bash
swift build
```

Expected: PASS.

- [ ] **Step 4: Run app and manually verify overlay**

Run:

```bash
./script/build_and_run.sh
```

Manual check:

- Create a reminder due in 1 minute.
- Confirm marquee appears at due time.
- Confirm countdown/due-now/overdue text updates.
- Click anywhere on alert band.
- Confirm Snooze 5m, Snooze 10m, and Dismiss appear.
- Confirm snooze hides overlay and reschedules reminder.
- Confirm dismiss hides overlay and marks reminder dismissed.

- [ ] **Step 5: Commit**

Run:

```bash
git add Sources/Notiyf/Services/MarqueeOverlayPresenter.swift Sources/Notiyf/App/AppController.swift
git commit -m "feat(overlay): show persistent marquee reminders"
```

## Task 8: Final Verification And Cleanup

**Files:**

- Modify only files that fail verification.

- [ ] **Step 1: Run unit tests**

Run:

```bash
swift test
```

Expected: PASS.

- [ ] **Step 2: Build and verify app launch**

Run:

```bash
./script/build_and_run.sh --verify
```

Expected: Swift build succeeds and `pgrep -x Notiyf` succeeds.

- [ ] **Step 3: Check Git status**

Run:

```bash
git status --short
```

Expected: no uncommitted source changes except generated ignored artifacts.

- [ ] **Step 4: Confirm CodeGraph is healthy**

Run:

```bash
codegraph status
```

Expected: CodeGraph reports an initialized index with no pending sync for edited source files.

- [ ] **Step 5: Resolve any verification failures in the owning task**

If Step 1, 2, or 4 fails, return to the task that introduced the failing file and make the smallest source or test fix there. Then rerun this final verification task from Step 1.

Expected: no source changes remain after Step 1, Step 2, Step 3, and Step 4 all pass.
