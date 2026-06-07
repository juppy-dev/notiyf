# Notiyf MVP Design

Date: 2026-06-07

## Goal

Notiyf is a macOS reminder app for people who miss important meetings because ordinary notifications are too easy to ignore. The MVP proves the core behavior: a reminder that is visually persistent, hard to miss, and easy to snooze or dismiss once acknowledged.

The first version is manual-only. Calendar integration and alternate alert graphics are deferred until the marquee reminder flow is working well.

## MVP Scope

Included:

- Native macOS app named Notiyf.
- Menu bar item with quick-add access.
- Reminder management window.
- Manual reminder creation, editing, deletion, dismissing, and snoozing.
- Persistent marquee alert overlay.
- Dynamic countdown and overdue messaging.
- Escalation behavior when the countdown reaches zero.
- Recent-overdue launch handling.
- Local-only persistence.

Deferred:

- Calendar integration.
- Airplane, bird, bee, or other alternate alert presenters.
- Recurring reminders.
- Extensive customization.
- Analytics or snooze history.
- UI automation for global overlay behavior.

## Product Surfaces

Notiyf has three user-facing surfaces.

### Menu Bar Item

The menu bar item keeps Notiyf available without requiring a full app window to stay open. It provides:

- Quick Add.
- Manage Reminders.
- Basic app commands such as quit.

### Reminder Management Window

The management window is a normal macOS window built in SwiftUI. It shows reminders grouped by status:

- Upcoming.
- Snoozed.
- Missed.
- Dismissed.

The window supports creating, editing, deleting, dismissing, and snoozing reminders.

### Marquee Overlay

The marquee overlay is the core MVP behavior. It is a borderless, always-on-top AppKit window spanning an alert band across the screen. The moving marquee text renders inside that overlay.

The overlay stays visible until the user dismisses or snoozes the reminder.

The entire alert band is clickable. Clicking the band reveals controls; the user does not need to click the moving text exactly.

Default overlay state:

- Marquee text is visible and moving.
- Dismiss and snooze controls are hidden.
- The overlay does not aggressively steal focus on appearance.

Interactive overlay state:

- Triggered by clicking anywhere on the alert band.
- Marquee pauses or slows.
- Controls appear: Snooze 5m, Snooze 10m, Dismiss.
- Controls hide after 8 seconds of no interaction or when the user presses Escape.
- Return dismisses when controls are visible.

## Architecture

Use a native Swift macOS app with a SwiftUI shell and narrow AppKit support for the overlay.

Primary components:

- SwiftUI app shell: owns the menu bar item, quick-add popover, and management window.
- Reminder store: holds reminders in memory and persists them locally.
- Scheduler service: watches due times, activates reminders, handles launch recovery, and coordinates snooze/dismiss transitions.
- Overlay presenter: owns the AppKit marquee window, marquee animation, countdown display, click-to-reveal controls, and escalation visuals.

The overlay presenter receives reminder display data and user actions. It does not own reminder persistence or scheduling rules.

User actions flow back to the reminder store:

- Snooze updates the reminder due time and hides the overlay.
- Dismiss marks the reminder dismissed and hides the overlay.

## Reminder Model

Each reminder stores:

- `id`
- `title`
- `dueAt`
- `status`
- `createdAt`
- `updatedAt`
- `lastFiredAt`
- `snoozeCount`

Supported statuses:

- `scheduled`: future reminder waiting to fire.
- `active`: currently being shown by the marquee overlay.
- `snoozed`: rescheduled after a snooze action.
- `dismissed`: completed and hidden.
- `missed`: overdue outside the recent launch threshold.

Snooze is intentionally simple for MVP. Choosing snooze sets `dueAt` to now plus the selected duration, increments `snoozeCount`, and sets `status` to `snoozed`.

## Persistence

Use a JSON file in Application Support for local persistence.

Reasons:

- The model is small.
- No relational queries are needed.
- Development inspection is simple.
- Initial migration burden is low.

Core Data or SwiftData can be introduced later if reminder complexity grows.

## Scheduling Behavior

The scheduler runs while the app is open and activates reminders when they are due.

On launch:

- Undismissed reminders overdue by 30 minutes or less activate immediately.
- Undismissed reminders overdue by more than 30 minutes become missed.
- Future reminders remain scheduled.

The scheduler computes display phase from `dueAt` and current time rather than storing phase separately.

Display phases:

- `countdown`: due time is in the future.
- `dueNow`: due time is within the first 10 seconds after arrival.
- `overdue`: due time has passed.

## Marquee Behavior

The marquee content updates dynamically.

Countdown phase:

- Shows text like `CEO Sync in 4m 38s`.
- Updates once per second.

Due-now phase:

- Shows text like `CEO Sync is starting now`.
- Triggers a short escalation burst.

Overdue phase:

- Shows text like `CEO Sync started 2m ago`.
- Remains persistent until dismissed or snoozed.

Escalation at zero:

- Increase marquee speed.
- Add a visual pulse or color inversion.
- Increase the alert strip height briefly for the first 10 seconds after the due time.

Only the marquee presenter owns these visual phase changes. No extra alert presenter types are introduced in the MVP.

## Testing

Automated tests should focus on pure logic:

- Reminder creation, editing, deletion, and status transitions.
- Scheduler due-time detection.
- Launch overdue threshold behavior.
- Snooze rescheduling.
- Dismiss behavior.
- Display phase calculation for countdown, due-now, and overdue states.

Overlay verification is lighter for MVP:

- Unit-test the presenter boundary where practical.
- Manually verify the always-on-top marquee, animation, click-to-reveal controls, snooze, and dismiss behavior during app runs.

## Initial Project Setup Notes

After the initial macOS project directory is created, CodeGraph should be initialized for this project so future structural questions and implementation work can use the CodeGraph MCP tools.

The initial app should be scaffolded before CodeGraph initialization so the index has meaningful Swift files and symbols to parse.
