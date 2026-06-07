# Notiyf

> Notifications, in your face.

```text
IMPORTANT THING IN 04:59 • IMPORTANT THING IN 04:59 • IMPORTANT THING IN 04:59 •
```

Notiyf is a macOS reminder app for people who routinely outsmart normal reminders.
If a calm little banner in the corner is not going to save you from missing the thing
you absolutely cannot miss, Notiyf tries a different tactic: it gets in your face.

## Why This Exists

There is a specific kind of failure mode this app is built for:

- you see the five-minute warning
- you keep doing whatever you were doing
- your brain says "one second"
- suddenly you are late and explaining yourself to someone important

Notiyf is meant to break that loop.

## What It Does

Current MVP:

- menu bar quick-add for reminders
- reminder management window
- local JSON persistence
- scheduler with launch recovery for recent overdue reminders
- full-width marquee overlay that stays up until you do something about it
- click-to-reveal snooze and dismiss controls
- countdown, due-now, and overdue states

Planned next:

- smoother marquee motion and better visual polish
- more expressive alert styles
- calendar integration
- recurrence and preference tuning

## Current State

This repo is already runnable and the core behavior exists, but it is still early.

- the menu UI works and needs polish
- the marquee overlay works and is actively being refined
- the product idea is real enough to try, break, and improve

That is deliberate. This is not a marketing shell pretending to be an app.

## Run It

Requirements:

- macOS 14+
- Swift toolchain with SwiftPM

From the project root:

```bash
./script/build_and_run.sh
```

Verification path:

```bash
./script/build_and_run.sh --verify
swift test
```

## Project Shape

```text
Sources/Notiyf/
  App/        app entrypoint and app controller
  Models/     reminder model and display phase
  Services/   scheduler and overlay presenter
  Stores/     persistence and state transitions
  Support/    small formatting helpers
  Views/      menu bar and reminder UI
```

## Built For

People who:

- work in front of a computer all day
- miss things because they get too distracted or too locked in
- need something louder than ordinary notifications

## Roadmap

- make the marquee feel smooth, deliberate, and impossible to ignore without flicker
- improve the quick-add and menu bar surfaces
- add alternate presenters like a tow banner or buzzing nuisance
- connect reminders to calendar events

## Notes

Notiyf is intentionally a little impolite.

That is the feature.
