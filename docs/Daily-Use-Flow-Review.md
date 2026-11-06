# Daily-use flow review — 2026-11-05

Scope: existing Lumi review branch; no PR or merge. Normal persistent-app UI checks ran only on Personal Universe 18 QA (iPhone 18 Pro / iOS 27.0), separate from the user's simulator and data. The only pre-existing project-file changes were Xcode ordering changes; these are preserved separately.

## What was tested

- Open the normal app without preview flags; create Daily Flow QA through name, seven-day duration, reminder permission, and Cluster selection. Grant notification permission on this isolated simulator.
- Enter an unfinished reflection, dismiss the discard prompt to keep writing, then explicitly discard. Reopen and observe an empty editor.
- Type Test with actual keyboard input, confirm completion, and reopen the completed day to verify the exact reflection and completion date. The completed day remains today's day rather than unlocking tomorrow.
- Open My Universe → challenge → Edit. Change the style, Cancel → Discard changes, reopen, and verify Cluster remains selected. Save Daily Flow Verified and Spiral.
- Terminate/relaunch the normal app. Verify the edited title and completed day on home; reopen the reflection and verify Test. Inspect the actual QA SwiftData store, verified recovery backup, and widget JSON read-only: title/style/seven days/completed reflection agree, and widget progress is 1/7. Evidence: C5/artifacts/daily-use/persisted-flow-check.json.
- Use a separate in-memory final-day fixture (--layout-review --layout-final-day) with six days complete. Navigate through My Universe to detail, complete day seven, reveal completion actions, choose New Challenge, and observe the actual creation screen. This is a real UI route check with disposable data, not a seven-calendar-day real-time trial.
- Install the final build, return to the normal persistent app, and open the widget URL personaluniverse://my-universe. Observe My Universe and the saved Daily Flow Verified challenge. Open personaluniverse://create-challenge while that challenge is active; observe My Universe, not a replacement-creation flow. The built app Info.plist contains the registered scheme. These are simulator URL-entry checks, not a physical Home Screen widget tap.
- Restore Device Hub's original keyboard-capture setting after typing checks.

## Issues found and fixed

1. **No next-day reminder after today's completion.** UI currentDay correctly stays on today, but scheduling incorrectly reused that completed day and returned. NotificationManager now selects the earliest unfinished day with a future reminder time. Creation after today's selected time also schedules the next eligible day. Planning tomorrow's reminder does not advance the UI's current day. Final completion/disabled reminders still cancel; writes remain serialized. The scheduler queues one next eligible reminder, not an unlimited multiweek backlog.
2. **Widget date froze at the last app sync.** WidgetUniverseData now derives its calendar presentation for each entry: today's index advances; earlier unfinished days display as missed; completed reflections/progress remain unchanged. WidgetProvider supplies an explicit next-midnight entry as well as asking for refresh. This changes widget presentation, not the persisted SwiftData model; WidgetKit still controls actual rendering time.
3. **New Challenge from completion detail did nothing.** The detail posted openNewChallenge without a receiver. ContentView now handles it by clearing event state and setting the new-challenge route.
4. **Widget links had no registered destination.** Added Configuration/App-Info.plist with the existing personaluniverse scheme and handlers for both existing widget hosts. An outdated create link redirects to My Universe if a challenge is active.
5. **Permission errors could claim the challenge was already saved during setup.** Permission messages now describe reminder availability without claiming a save has occurred.

## Automated verification

The full standalone regression runner passed against production code using temporary/in-memory data. New controlled-clock checks cover tomorrow's reminder after completion, creation after today's reminder time, edited reminder titles, final cancellation, and widget midnight/missed-day/end-date presentation. A permission-race test now explicitly fixes today's future reminder time and injected clock, so it tests completion of the actual pending day rather than accidentally selecting tomorrow. Existing save failures, metadata rollback, database/WAL backup restoration, widget fallback, and notification ordering checks still pass. Debug and Release app/widget builds passed without warnings; git diff --check passed.

## Real-iPhone checks still required

- Install/update the app with its real signing/App Group configuration. Add small/medium/large widgets and check updated title/style/progress plus actual widget taps from cold and running app states.
- Choose a future reminder time; background/close the app and check actual delivery, then complete a day and verify the next eligible day's reminder and cancellation. Check denied permission, re-enabling in Settings, Focus/notification-summary effects, and behavior after multiple days without opening the app. Scheduling requests in tests do not prove OS delivery.
- Leave a widget overnight and compare its day/missed states with the app after midnight. Check time-zone/DST changes and foreground/background transitions. Midnight entries do not guarantee second-exact screen updates.
- Run creation, reflection keep/discard/complete, edit/cancel/save, restart, and final completion on the real keyboard/screen. Check text size, touch targets, haptics, and whether glow remains comfortable at low brightness.
- Existing-installation upgrades, real low-storage/interrupted-save recovery and physical-device performance remain release checks. Do not deliberately damage personal data to exercise recovery.
