# Reminder Editing (Detail Pane) — Design

Date: 2026-06-13
Tracking: DEV-75 (closes the last open MVP item)

## Goal

Let users edit an existing reminder's title and due time from the management
window. `ReminderStore.update(id:title:dueAt:now:)` already exists; only the UI
is missing. This wires editing into the management window's currently-empty
detail pane.

## Interaction

- The sidebar `List` becomes selectable via `@State selection: Reminder.ID?`.
  Each reminder row carries `.tag(reminder.id)`.
- Selecting a reminder shows an editor in the detail pane, pre-filled with its
  title and due time. With no selection, the existing
  `ContentUnavailableView("Select or create a reminder")` remains.
- The detail editor contains: a title `TextField`, a `DatePicker`
  (`.date` + `.hourAndMinute`), a **Save** button (disabled when the trimmed
  title is empty), and a **Delete** button.

## Save semantics

Saving calls `store.update(...)`, which sets the new title and due time and
forces `status = .scheduled`. This is the existing store contract and the
intended behavior: editing any reminder — including a Missed, Snoozed, or
Dismissed one — revives it into Upcoming. No store or test changes to that
contract.

Delete removes the reminder and clears the selection, returning the detail pane
to the empty state.

## Components

Three files touched, one new. Each view keeps a single purpose.

1. **`ReminderEditView` (new)** — the detail-pane editor. Initializes its
   `@State` (title, dueAt) from the passed `Reminder`. The parent applies
   `.id(reminder.id)` so SwiftUI rebuilds it with fresh state when the
   selection changes. Save is disabled while the trimmed title is empty.
2. **`ReminderListView`** — adds `@State selection: Reminder.ID?`, binds
   `List(selection:)`, tags each row with its id, and swaps the detail pane to
   show `ReminderEditView` for the reminder whose id matches the selection
   (looked up in `store.reminders`). Falls back to `ContentUnavailableView`
   when no reminder matches.
3. **`AppController`** — adds `func update(_ reminder: Reminder, title: String,
   dueAt: Date)` delegating to `store.update(id:title:dueAt:)`, mirroring the
   existing `createReminder` / `snooze` / `dismiss` / `delete` passthroughs.

The existing `ReminderEditorView` (Quick Add / create form) is left unchanged —
separate purpose and copy.

## Edge cases

- The detail pane looks up the reminder by id on each render, so a saved edit
  that moves the reminder to a different section keeps it selected and visible.
- If the selected id no longer matches any reminder (e.g. after delete), the
  detail pane shows the empty state.

## Testing

- `store.update` is the only pure logic involved. Confirm it is covered by a
  unit test (title and dueAt change, `status` becomes `scheduled`); add one if
  missing.
- The detail-pane wiring (selection, pre-fill, save, delete) is verified
  manually during an app run, consistent with the MVP testing approach for UI
  surfaces.

## Out of scope (YAGNI)

- No Cancel/revert button — selecting away discards unsaved edits (standard
  detail-pane behavior).
- No snooze/dismiss controls in the detail editor — already available in the
  row context menu.
- No validation beyond the empty-title guard.
