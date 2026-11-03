# Visual cohesion and editing navigation

2026-11-03 — follow-up on the existing review branch. No PR or merge.

## Design decision

Challenge editing belongs to the challenge detail screen opened from My Universe. It is an occasional action, while the home screen centers today's reflection and progress. The home toolbar now contains only My Universe; a contextual Edit action appears on the detailed challenge page, outside its completion event. It is no longer presented as a global settings icon beside navigation. Galaxy entry points also have explicit accessibility labels/actions.

The trade-off is one additional navigation step to edit the active challenge. If editing later proves frequent, a separate action near the home challenge title would be the place to consider a shortcut. It should not share the My Universe toolbar group.

## Settings and recovery treatment

- Black background and a static, subdued star field for focused editing/recovery.
- Recovery uses a 22-point default title; the revised editor uses a compact 17-point header/name field, 15-point labels/actions and readable preservation text, all using Dynamic Type styles.
- Fine white outlines, restrained white fills and at least 44-point action targets. No blue filled retry button or gray system form block.
- Three actual galaxy thumbnails show the appearance choices. The redundant large progress preview was removed because a zero-progress challenge showed only a floating dot and unexplained empty space.
- Save is disabled for unchanged/blank input. Name/style remain drafts until a successful save. Cancel confirms discarding changes; swipe dismissal is blocked while changed drafts exist.
- Settings save failures stay visibly beneath the fixed editing header with a real Try again action. Other save failures use the same notice typography in a black sheet. Its Got it button acknowledges the error; it does not pretend to retry the operation.
- Startup and integration recovery retain their actual retry/restore/settings actions, now with the common white-outline button treatment. Retry is guarded while in flight, and integration actions stack at accessibility text sizes.

`UniverseAppearance.swift` owns the shared action, quiet backdrop and notice treatment. A recovery message remains readable content rather than a decorative ambient event. Destructive discard/restore confirmations retain native platform confirmation behavior.

Apple documents the supported APIs used for [toolbar background visibility](https://developer.apple.com/documentation/swiftui/customizabletoolbarcontent/sharedbackgroundvisibility(_:)) and [sheet backgrounds](https://developer.apple.com/documentation/swiftui/view/presentationbackground(_:)).

## Ambient event assessment and coverage

The spacecraft already share the app's monochrome points, thin lines and soft light. Their small distant silhouettes are a better fit than bright filled panels. Their technical shapes will remain more literal than the abstract galaxies; they should therefore remain rare and subordinate, rather than grow into prominent illustrated stickers. Satellite has two wings and a compact body; station has a longer truss and four panel pairs.

The old generator mostly used middle-height side-to-side passes and did not deliberately guarantee visible lower-screen passes. The new generator chooses one of four normalized scene-height lanes:

| Lane | Height |
|---|---|
| Upper | 6–24% |
| Upper middle | 28–49% |
| Lower middle | 53–75% |
| Lower | 80–94% |

Start/end heights and the shallow arc remain inside the chosen lane, so a lower pass actually stays near the bottom during its visible middle. Direction, speed, size, tilt and brightness vary per event. Paths are continuous edge-to-edge passes. Durations are meteor 1.3–2.1s, satellite 10–17s, station 18–26s. Quiet waits remain the mixed 10–28 / 35–65 / 80–120s schedule; the demonstration selector shortens waits only in Debug.

These are positions within the app's space backdrop, not overlays on the phone's system UI. Home, My Universe, challenge detail, challenge creation and event screens share the backdrop. Opaque settings/reflection/error surfaces intentionally obscure those objects so focused tasks remain quiet. Foreground text/controls stay above the events, which cannot receive taps. Transparent gaps can reveal the background; this is not per-text collision avoidance.

## Verification

Seeded trajectory checks sample the full arc, verify upper and genuinely lower midpoint coverage, both directions, duration bounds and varied waits. Existing storage/widget/notification regressions remain included. Debug and Release app/widget builds are checked. Visual screenshots and any motion demonstration are described separately from production timing evidence.

## Visual acceptance and a rendering fix

The actual recording exposed a visibility bug left by an earlier optimization: an initially empty Group could wait for its own onAppear before inserting any child, so the scheduler ran while no event appeared. AmbientSpaceEventLayer now keeps a stable transparent layout node, and its overlay inserts the event only when visible/active. It retains touch pass-through and background ordering. A new recording verified visible satellite and station passes; the demonstration's first wait was lengthened to let the first UI frame settle before the very short meteor.

A separate Personal Universe Visual QA simulator preserved the original session when external input was detected. In that isolated copy, the home → My Universe → detail → Edit path, disabled unchanged Save, changed selection, discard confirmation, successful saving, a real startup failure, Try again and confirmed backup restoration were checked. Actual settings and recovery screenshots are stored outside the repo under C5/artifacts/day7-cohesion/.

The app now declares its existing dark appearance in the launch configuration as well as in SwiftUI. Destructive confirmations remain native. The motion clips demonstrate selected types and shortened waits, not the production interval distribution. Seeded tests separately cover the actual upper/lower lane generator and varied production durations/waits.

Final acceptance: warning-free Debug/Release app/widget builds and the full regression runner passed. The final 60.47-second real app recording (`events-demo-final.mp4`, outside the repo) visibly contains a meteor around 0:09, satellite around 0:16 and station around 0:35, including lower-screen passes. Navigation occurs during the clip; it is not a fixed-screen performance benchmark. Type order and waits are selected for demonstration, while paths, sizes and movement speeds use the actual generator. Final generated QA data was also checked read-only after editing/restoration: title, style, all 30 days and widget/backup snapshots agreed.

## Edit-first revision after hierarchy feedback

The first compact revision used a single Cancel — Edit challenge — Save header; the follow-up below replaces that arrangement. The decorative heading/subtitle were removed; name and appearance labels/fields are left-aligned with 24-point section spacing. Selection uses a checkmark and clearer outline. The preservation message is readable 15-point default text with explicit wording. Sheet height follows measured header/content size instead of a fixed 75% screen fraction, and it can still expand/scroll. That first revision used a two-row header for accessibility text sizes. The compact editor was inspected in the Visual QA simulator before changing event visibility.

The previous motion preview was too faint for useful review. Event outlines, opacity and modest size increases now improve visibility without a whole-screen flash. Meteors are slightly longer to make their short pass perceivable. Active challenge and completion-event lighting were not changed in this revision. A new capture is separate from the previously delivered dim preview.

Latest verification: the compact edit sheet was visually inspected and captured as `edit-compact.png`; unchanged Cancel dismissed it without altering data. Warning-free Debug/Release builds and the regression runner passed. The new `events-demo-clearer.mp4` recording is 60.69 seconds and visibly shows the meteor at about 0:09, satellite at 0:16 and station at 0:32. Representative exact-time frames were inspected. Demonstration order/waits are selected; actual renderer, random paths and movement durations are used. These artifacts are local under C5/artifacts/day7-cohesion/.

## Separate title and underlined name field

Following the next hierarchy review, Cancel and Save now occupy their own action row. Edit challenge is a separate, larger, left-aligned heading below it, marked as an accessibility header at every text size. The name field uses the setup screen’s one-point underline and vertical padding instead of a rounded box; its underline strengthens during focus. The compact measured-height sheet and save/discard behavior remain. Debug app/widget build passed, and the actual simulator sheet was visually verified and captured as `edit-underline.png` outside the repository.
