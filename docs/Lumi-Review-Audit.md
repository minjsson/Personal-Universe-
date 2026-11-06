# Lumi review audit

## Status: reliability follow-up implemented; not a release sign-off

This audit distinguishes changes made from review points intentionally retained or deferred. The visual feature requests (challenge settings and ambient events) are additional product work; they do not count as completion of every Lumi review item.

| Review point | Evidence / decision | Status |
|---|---|---|
| Startup fatalError | `PersistentStoreLoader` reports failure; `DatabaseRootView` offers retry. The original store is neither deleted nor silently replaced with temporary storage. | Implemented; now includes verified-backup restore with original-file preservation. This is not arbitrary corrupt-data salvage. |
| Overall error handling | Main creation, completion, positioning and metadata-saving paths surface failures and stop success-only effects. Reflection input stays in a draft. | Implemented for reviewed paths: notification permission/scheduling and widget failures now surface recovery state and retry. |
| Value-struct initializers | Removed redundant assignments from GalaxyPoint, GalaxyStar and GalaxyBody. Kept `let revealAt: Double` because all callers supply it, including nonzero reveal thresholds. The synthesized initializer preserves those calls. | Implemented with behavior preserved. |
| Suggested `let revealAt = 0` | This is not equivalent to the repository's generator requirements; it would fix the constant and lose the adjustable initialization argument. | Intentionally not applied. |
| GalaxyBodyView initializer | `_orbitAngle = State(initialValue: galaxyBody.startingAngle)` performs meaningful initialization. | Intentionally retained. |
| GalaxyOrbitModifier | Confirmed there were no callers, then removed the unused type/file and target entry. | Implemented. |
| Shared symbol names | App/widget sparkle and repeated navigation symbols use `UniverseSymbols`. The symbol String itself still needs availability/visual verification. | Implemented for actual repeated sparkle uses. |
| Font/opacity constants | Unrelated numerical values were not globally merged. Event appearance values remain local to their rendering owner. | Selective application; not a full design-token audit. |
| HapticManager Singleton | Existing shared UIKit utility remains. It is not mutable screen state and no concrete replacement requirement was established. | Not converted. Environment is a delivery choice, not a universal requirement. |
| Initializer / static study | Day 7 note explains static values, shared references, private init, and meaningful custom initialization. | Documented. |
| View optimization | One window-owned ambient scheduler avoids restarting independent timers across navigation; Reduce Motion and inactive scenes stop ambient animation. | Targeted optimizations now include Canvas stars, cached galaxy geometry, duplicate backdrop removal, and visibility/lifecycle pauses; no measured FPS claim. |
| MV versus MVVM | Models retain domain rules; small owners coordinate storage opening and metadata saving. No blanket ViewModel conversion. | Applied as responsibility-based design, not a completed architecture rewrite. |
| BookMark practice | MV/MVVM source and tests were inspected in Day 6B. | Study comparison done; no claim that the BookMark tests were executed. |
| TCA / Confluence assignment | The full assignment page was not supplied and TCA was explicitly deferred. | Not completed in this branch. |

## Verification and limits

The app and embedded widget Simulator builds passed. Focused executable regressions cover storage-opening failure followed by success, metadata-saving failure and restoration, blank-title validation, unchanged progress/dates/day membership, nonzero revealAt, and randomized event bounds/variation.

These checks are not a substitute for real-device notification/widget delivery, existing-store migration, actual low-storage behavior, every damage/migration scenario, performance profiling, or a full accessibility review. Remaining manual checks are listed in `Lumi-Review-Validation.md`.

## Motion-recording method

The Debug build supports `--ambient-demo`, which shows meteor, satellite and station in a fixed order with a five-second initial wait and two-second later waits (the original captures used two-second waits throughout). It uses the actual event renderer, random geometry and actual movement-duration ranges. This demonstration is not evidence of the production waiting-time distribution.

A separate launch with `--ambient-timing-log` uses the normal unaccelerated random scheduler and logs chosen waits and event start/duration values. Neither recording flag is included in Release builds.

## Captured evidence

Actual simulator recordings were created outside the repository under `C5/artifacts/day7-motion/`:

- `all-three-in-app.mp4`: 47.5-second edited demonstration. It joins the meteor/satellite segment with a clear station recording. Movement is at actual speed, but waits are shortened and type order is selected for demonstration. Meteor is visible around 0:05, satellite around 0:12, station around 0:34.
- `normal-random-timing.mp4`: approximately 181 seconds using the ordinary random scheduler, without accelerated waits. Navigation occurs during the recording; this is not a fixed-screen benchmark.
- `events-demo.mp4`: original 60-second demonstration including a settings sheet obscuring the background during the first station pass.
- `normal-timing-summary.txt`: filtered chosen-wait and start/duration log.

The normal capture selected quiet waits of 25.48, 23.80, 37.86 and 42.35 seconds before meteor (1.31s), satellite (11.32s), meteor (1.53s) and satellite (10.81s). Actual elapsed delays can exceed selected waits under simulator load. This short sample demonstrates varied cadence, not a statistical proof of randomness or coverage of every kind.

Representative frames of all three moving objects were inspected. The source confirms stars → ambient events → foreground content, and an opaque settings sheet covered the background during the original demonstration. Transparent foreground regions naturally reveal the backdrop; the clips do not prove collision avoidance for every possible text/layout combination.

Debug and Release app/widget builds passed. The recording selectors/log strings were absent from the inspected Release executable. Focused regression checks passed after the recording instrumentation was added.

## 2026-11-03 recovery follow-up

Database backup/restore, notification/widget recovery and rendering changes are implemented and detailed in [Recovery and view optimization](Recovery-and-View-Optimization.md). The standalone regressions now include real temporary SQLite/WAL files, SwiftData backup reopening, corrupt widget data and injected notification failures. An isolated simulator corruption/restore flow was also checked. This supersedes the former deferred status of those implementation items; device delivery and release verification remain distinct.

## Final re-audit

[Final review in Korean](Lumi-Final-Review.md) maps the original pasted review item by item. It also records additional fixes found during reinspection: missing-primary-store backup protection, obsolete/overlapping notification requests, completion animation task ownership, remaining trivial initializers and Preview force-try removal. These are code and targeted regression findings; they are not a universal release guarantee.

## Visual follow-up

[Visual cohesion](Visual-Cohesion.md) documents detail-only editing, matching recovery/settings styling, whole-scene event lanes, and the initially empty visibility-layer bug found through actual recording and corrected with a stable layout node. Generator tests alone did not establish visibility.
