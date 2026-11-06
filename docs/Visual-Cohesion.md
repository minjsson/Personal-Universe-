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

## Current challenge, growth and completion lighting

The active galaxy now keeps more of its light between twinkles (78% instead of 55% for stars; 72% instead of 45% for special twinkling bodies). Its local atmosphere and star shadows are stronger. My Universe adds a clearer active halo and thin orbit outline; archived galaxies retain their quiet styling. Revealed star counts still follow saved progress: an early challenge remains sparse rather than pretending to be fully grown. The home screen's already-white current-day symbol is unchanged.

Growth uses a brighter local atmosphere and a more legible 1.5-second expanding ring. Completion uses the brighter star treatment for the celebration only, two clearer waves, a temporary burst light that fades during settling, and a stronger central afterglow behind the sharp stars. All completion illumination is clipped to a maximum 340-point central artwork region below the text/action layer; the secondary completion prompt also has higher contrast. There is no screen-wide white overlay. Existing event durations, progress calculations and persisted data are unchanged.

An isolated Debug-only launch preview reuses the real GalaxyView/GrowthEventView/CompletionEventView renderers without opening the database or contacting services. Its title/day caption is a review fixture, not a new production layout. Current galaxies were inspected in expanding/cluster/spiral at 35%; growth and completion were recorded at actual animation speed, including extracted pulse/burst frames. Completion's reveal tap displayed the real message/buttons and their readability was visually checked. The normal My Universe screen was separately inspected with the early-progress QA challenge. Artifacts are outside the repository under C5/artifacts/day7-cohesion/: lighting-my-universe.png, lighting-current-*.png, lighting-growth.mp4, lighting-completion.mp4, and lighting-completion-actions.png.

Reduce Motion was enabled through Settings only on Personal Universe Visual QA, both real event views were launched, and pairs of screenshots one second apart were byte-identical for each view. They retain finished illumination without expanding waves, breathing or twinkle. The original off setting was restored and verified. Event tasks now distinguish inactive scenes from Reduce Motion: an inactive scene waits rather than prematurely marking the entrance animation complete. Warning-free Debug/Release app and widget builds passed. This is simulator visual verification, not a physical-device brightness or full screen-size certification.

## Simpler editor and responsive iPhone layouts — 2026-11-05

Removed the Edit challenge heading and selection checkmark. The sheet now contains Cancel/Save, Name with a single-line underlined field, Galaxy style, and one short preservation sentence. Border, local light and VoiceOver selected traits identify the selection. The grid's minimum card width scales with Dynamic Type, reflowing as needed. The single-line field's Done key dismisses the keyboard; the old multiline field could insert a newline.

My Universe's toolbar label keeps its full intrinsic width instead of truncating. Home content can scroll with long titles or constrained height; day buttons use flexible column widths and at least 44-point height. Journey artwork adapts to available width. Setup and reflection content can scroll, and reflection sheets can expand beyond a fixed fraction. Growth/completion drawings scale from a common coordinate space; completion uses separate text/art/action regions and a side-by-side landscape layout so glows cannot cover the controls.

Verification used isolated iPhone SE (3rd generation), iPhone 18 Pro and iPhone 18 Pro Max simulators, running iOS 26.5/27.0. Actual home/editor views used disposable in-memory fixtures via Debug-only --layout-review (optional --layout-editor/--layout-setup/--layout-reflection/--layout-long-title). Screenshots under C5/artifacts/day7-responsive/ were inspected; initial transition captures were replaced before delivery. The full My Universe label is visible on the iPhone 18. Compact portrait, long title, setup and reflection were inspected. The compact editor was additionally checked with the real system accessibility-large text setting in portrait and landscape; scrolling reached the selected third style and footer while Cancel/Save stayed visible. The original large setting was restored. The final Done key was tested in the actual keyboard. Completion text, artwork and both actions were checked in compact portrait/landscape using the real event renderer. Debug/Release app and widget builds and the existing storage/service regression runner passed.

These are adaptive layout improvements and representative simulator checks, not certification of every device/OS/text-size combination. The app's minimum iOS version is still 26.5. Duo folding transitions, native iPad/Mac layouts and physical-device verification are not covered by this pass. No PR or merge.

## Match the editor to the existing screens

The edit sheet now uses the same centered, regular-weight, underlined name field as challenge setup, through UniverseNameFieldStyle. Title3 preserves the setup field's 20-point default while following Dynamic Type. Section captions and the preservation sentence are quieter and centered, matching the app's centered composition. Unselected galaxy cards have transparent fill and a subtle outline; selection keeps its border and local galaxy illumination with only a very slight fill. The editor's star field is dimmed further to keep it closer to focused reflection surfaces. No heading or checkmark was reintroduced. Save/discard behavior, adaptive grid and scrolling remain. Debug app/widget build passed; real setup/editor renderings were captured in the isolated iPhone 18 simulator as cohesive-setup.png and cohesive-editor.png under C5/artifacts/day7-responsive/ and visually compared.

## My Universe back-arrow consistency

My Universe now replaces the system glass-backed back button with the same UniverseBackButton used in challenge setup: 17-point medium chevron, white at 0.8 opacity, plain style and a 44 × 44-point rectangular tap area. Its toolbar item explicitly hides the shared glass background; the title remains centered. The shared component includes a Back accessibility label. Debug app/widget build passed. The actual My Universe screen was visually inspected in the isolated iPhone 18 Pro simulator using disposable in-memory layout data, and tapping Back returned to home. Screenshot: C5/artifacts/navigation-cohesion/my-universe-back.png. Edge-swipe navigation and physical-device behavior were not assessed in this focused check.

Follow-up: removed the redundant My Universe navigation title so the overview remains a quiet galaxy canvas. Challenge detail retains the actual challenge name, and its back control now also uses UniverseBackButton with the toolbar glass background hidden. A fresh Debug app/widget build passed; the overview and detail were visually checked in the isolated simulator, and the detail back arrow returned to the untitled overview. These observations supersede the centered overview title described above; the detail title remains centered.

## Navigation control audit

All custom navigation controls now use UniverseNavigationButtonStyle: flat, borderless, subheadline text, 0.8 white when enabled and 0.3 when disabled, a minimum 44-point tap area and subdued pressed feedback. Back and forward chevrons share UniverseNavigationArrow's 17-point medium symbol. This covers setup, home/My Universe, detail/Edit, editor Cancel/Save, Begin and completion destinations. Toolbar items explicitly hide the system shared glass background. Native system alerts and the reflection completion sparkle retain their separate roles. The app/widget Debug build passed; physical-device appearance, large-text layout and edge-swipe navigation remain manual checks.
