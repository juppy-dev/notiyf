# Reminder Editing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users edit an existing reminder's title and due time from the management window's detail pane (closes DEV-75).

**Architecture:** The sidebar `List` in `ReminderListView` becomes selection-driven. Selecting a reminder shows a new `ReminderEditView` in the currently-empty detail pane, pre-filled from the reminder. Save delegates through a new `AppController.update` passthrough to the existing `ReminderStore.update(...)`, which forces `status = .scheduled` (editing revives a reminder into Upcoming). Delete clears the selection.

**Tech Stack:** Swift, SwiftUI, AppKit (macOS 14+), SwiftPM, XCTest.

Reference spec: `docs/specs/2026-06-13-reminder-editing-design.md`

---

### Task 1: Regression test for `ReminderStore.update`

`ReminderStore.update(id:title:dueAt:now:)` already exists but is untested. Add coverage for the revive-on-edit contract (title + dueAt change, `status → scheduled`, `updatedAt` set, persistence written). This test passes on first run — it is regression coverage for existing behavior, not red-green TDD.

**Files:**
- Test: `Tests/NotiyfTests/ReminderStoreTests.swift` (add one method; file ends at the closing `}` on line 63)

- [ ] **Step 1: Add the test method**

Insert this method inside `final class ReminderStoreTests` (e.g. after `testSnoozeReschedulesReminder`). It mirrors the existing tests' use of `InMemoryReminderPersistence` already defined at the top of the file.

```swift
    func testUpdateRevivesReminderAndReschedules() throws {
        let persistence = InMemoryReminderPersistence()
        let store = try ReminderStore(persistence: persistence)
        let reminder = try store.create(title: "Standup", dueAt: Date(timeIntervalSince1970: 2_000))
        try store.dismiss(id: reminder.id)
        let newDue = Date(timeIntervalSince1970: 5_000)
        let now = Date(timeIntervalSince1970: 3_000)

        try store.update(id: reminder.id, title: "CEO Sync", dueAt: newDue, now: now)

        let updated = try XCTUnwrap(store.reminders.first)
        XCTAssertEqual(updated.title, "CEO Sync")
        XCTAssertEqual(updated.dueAt, newDue)
        XCTAssertEqual(updated.status, .scheduled)
        XCTAssertEqual(updated.updatedAt, now)
        XCTAssertEqual(persistence.savedReminders, store.reminders)
    }
```

- [ ] **Step 2: Run the test**

Run: `swift test --filter ReminderStoreTests/testUpdateRevivesReminderAndReschedules`
Expected: PASS (the `update` method already implements this behavior).

- [ ] **Step 3: Commit**

```bash
git add Tests/NotiyfTests/ReminderStoreTests.swift
git commit -m "test(store): cover update revive-on-edit behavior"
```

---

### Task 2: Add `AppController.update` passthrough

Mirror the existing `createReminder` / `snooze` / `dismiss` / `delete` passthroughs so the UI has a single entry point for editing.

**Files:**
- Modify: `Sources/Notiyf/App/AppController.swift` (add a method alongside `createReminder`, around line 40-42)

- [ ] **Step 1: Add the method**

Insert immediately after the `createReminder(title:dueAt:)` method:

```swift
    func update(_ reminder: Reminder, title: String, dueAt: Date) {
        try? store.update(id: reminder.id, title: title, dueAt: dueAt)
    }
```

- [ ] **Step 2: Build to verify it compiles**

Run: `swift build`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Sources/Notiyf/App/AppController.swift
git commit -m "feat(app): add reminder update passthrough"
```

---

### Task 3: Create `ReminderEditView`

The detail-pane editor. Initializes `@State` from the passed reminder; the parent applies `.id(reminder.id)` (Task 4) so SwiftUI rebuilds fresh state when the selection changes. Save is disabled while the trimmed title is empty. Copy and field layout follow the existing `ReminderEditorView` (Quick Add) for visual consistency.

**Files:**
- Create: `Sources/Notiyf/Views/ReminderEditView.swift`

- [ ] **Step 1: Create the file**

```swift
import SwiftUI

struct ReminderEditView: View {
    let reminder: Reminder
    let onSave: (String, Date) -> Void
    let onDelete: () -> Void

    @State private var title: String
    @State private var dueAt: Date

    init(
        reminder: Reminder,
        onSave: @escaping (String, Date) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.reminder = reminder
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: reminder.title)
        _dueAt = State(initialValue: reminder.dueAt)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Reminder")
                .font(.headline)

            TextField("What can't you miss?", text: $title)
                .textFieldStyle(.roundedBorder)

            DatePicker("Alert me at", selection: $dueAt, displayedComponents: [.date, .hourAndMinute])

            HStack {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Spacer()

                Button {
                    guard !trimmedTitle.isEmpty else { return }
                    onSave(trimmedTitle, dueAt)
                } label: {
                    Label("Save", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
                .disabled(trimmedTitle.isEmpty)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `swift build`
Expected: Build succeeds (view is not yet referenced; this confirms it compiles on its own).

- [ ] **Step 3: Commit**

```bash
git add Sources/Notiyf/Views/ReminderEditView.swift
git commit -m "feat(ui): add reminder detail editor view"
```

---

### Task 4: Wire selection + detail editing into `ReminderListView`

Make the sidebar list selection-driven and render `ReminderEditView` in the detail pane for the selected reminder. Look the reminder up by id each render so a saved edit that moves it between sections stays selected and visible; fall back to the empty state when no reminder matches (e.g. after delete).

**Files:**
- Modify: `Sources/Notiyf/Views/ReminderListView.swift` (whole `body`)

- [ ] **Step 1: Add selection state**

Add this stored property to `ReminderListView`, directly under `let controller: AppController`:

```swift
    @State private var selection: Reminder.ID?
```

- [ ] **Step 2: Bind the list selection and tag rows**

Change the `List {` opening line to:

```swift
            List(selection: $selection) {
```

Add `.tag(reminder.id)` to each reminder row so the selection value matches `Reminder.ID`. The row is the `VStack` that already carries `.contextMenu { ... }`. Apply the tag after the context menu modifier:

```swift
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
                            .tag(reminder.id)
```

- [ ] **Step 3: Replace the detail pane**

Replace the existing detail closure:

```swift
        } detail: {
            ContentUnavailableView("Select or create a reminder", systemImage: "bell.badge")
        }
```

with:

```swift
        } detail: {
            if let id = selection,
               let reminder = controller.store.reminders.first(where: { $0.id == id }) {
                ReminderEditView(
                    reminder: reminder,
                    onSave: { title, dueAt in
                        controller.update(reminder, title: title, dueAt: dueAt)
                    },
                    onDelete: {
                        controller.delete(reminder)
                        selection = nil
                    }
                )
                .id(reminder.id)
            } else {
                ContentUnavailableView("Select or create a reminder", systemImage: "bell.badge")
            }
        }
```

- [ ] **Step 4: Build and run the full test suite**

Run: `swift build && swift test`
Expected: Build succeeds; all tests pass (18 existing + 1 new from Task 1 = 19).

- [ ] **Step 5: Manual verification (app run)**

Run: `script/build_and_run.sh` (or `script/build_and_run.sh --verify` if available)
Verify in the running app:
- Selecting a reminder in the sidebar opens the editor in the detail pane, pre-filled with its title and due time.
- Changing the title and/or time and pressing Save (or Return) updates the row; an edited Missed/Snoozed/Dismissed reminder moves into Upcoming, and stays selected.
- Save is disabled when the title field is empty.
- Delete removes the reminder and the detail pane returns to "Select or create a reminder".
- Selecting a different reminder swaps the editor to that reminder's values (no stale fields).

- [ ] **Step 6: Commit**

```bash
git add Sources/Notiyf/Views/ReminderListView.swift
git commit -m "feat(ui): edit reminders from the detail pane"
```

---

### Task 5: Close out DEV-75

- [ ] **Step 1: Tick acceptance criteria and mark the issue Done**

Update DEV-75 in Linear: check the acceptance-criteria boxes for the editor pre-fill, save (title + time), and delete; move status to `Done`. Follow the conventions in the `linear-project` memory.

---

## Notes for the implementer

- `Reminder` is `Identifiable` (`id: UUID`), so `Reminder.ID` is `UUID?` for the optional selection.
- `ReminderStore.reminders` is `@Observable`, so the detail pane re-evaluates the lookup when the store mutates — no manual refresh needed.
- Active reminders (currently shown by the overlay) are not in any of the four sidebar sections but remain in `store.reminders`. This plan does not surface them in the sidebar, so they are not selectable for editing — consistent with the spec's scope.
- Do not modify the existing `ReminderEditorView` (Quick Add). It stays the create-only form.
