# Lumi review branch — validation

Issue: https://github.com/minjsson/Personal-Universe-/issues/1

Branch: review/1-lumi-day7-reliability-and-universe-settings

## Automated checks

- iPhone Simulator Debug and Release builds for PersonalUniverse (including embedded widget extension); final builds passed without warnings.
- `bash Tests/Day7Regression/run.sh`: runs the production model/metadata editor/store loader on macOS with an in-memory SwiftData container. Covers successful metadata save, failed-save restoration, blank-title rejection, unchanged progress/dates/days, startup failure followed by successful retry, and nonzero revealAt.
- `git diff --check`.

The regression runner is a standalone Swift executable, not an Xcode XCTest target. It requires macOS 14+ and Xcode. It does not touch the app's persistent store.

## Simulator smoke check

The app launched successfully in an isolated iPhone 17 Pro / iOS 26.5 simulator. Startup and title/duration/reminder creation screens were inspected. The initial pass was interrupted; the 2026-11-03 follow-up additionally verified title editing, shared widget snapshot/backup propagation, and controlled database restoration in a separate Recovery QA simulator. See the follow-up report for the exact scope.

## Manual checks before release

- Open current-challenge settings and settings from My Universe; save/cancel title/style edits and reopen them after an app restart.
- Confirm the active widget and reminder title update after a successful edit; real notifications and widget delivery require device verification.
- Complete a normal day and final day from both routes; check one completion event, matching model state, and the midnight day-selection rule.
- Simulate save failure in the UI and confirm draft remains, no success event appears, and retry works.
- Dismiss an unfinished reflection using Close, choose Keep writing, then Discard; reopen and verify no draft was persisted.
- Watch decorative events, check touch pass-through and Reduce Motion, and evaluate brightness on a real device.
- Existing-database upgrade and genuine low-storage behavior still require manual checks. Additional temporary-file tests and an isolated simulator now exercise corruption/restore; see Recovery-and-View-Optimization.md.

## Scope notes

No destructive database reset or automatic in-memory fallback is introduced. Notification/Widget failures now have visible recovery state and retry; see Recovery-and-View-Optimization.md. Layout, challenge length, and start-date rules are preserved. No PR or merge is requested.

## Ambient event follow-up

The initial cyan/six-second effects were replaced by the cohesive monochrome designs and window-scoped varied scheduler described in [Ambient event refinement](Ambient-Event-Design.md). The Simulator build and the expanded seeded regression checks passed. A static render of the actual event/galaxy Views was visually inspected; real-time timing and device brightness are still manual checks.

## In-app motion evidence

The three effects were recorded in the isolated simulator, with a separate approximately three-minute normal-cadence capture. Selected frames were inspected and an opaque settings sheet was observed to hide the backdrop. Recording method, sample timings, and remaining limits are documented in [Lumi review audit](Lumi-Review-Audit.md). This improves visual evidence but does not replace a real-device brightness/accessibility/performance review.

## 2026-11-03 follow-up

See [Recovery and view optimization](Recovery-and-View-Optimization.md) for the new real-file backup/restore, widget and notification regressions, isolated simulator restoration evidence, and rendering changes. These checks extend the initial in-memory validation described above. No PR or merge.
