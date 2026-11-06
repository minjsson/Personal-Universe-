# Ambient event refinement

The first version used cyan panels and the same six-second traversal for every event. Each SpaceBackground also owned its own timer, so navigation could restart a recognizable rhythm.

## Appearance

- White points, fine wireframe lines and soft white glow match the existing galaxy and background stars.
- Meteors have a small head and a thin fading tail. Satellites/stations use distant, low-contrast silhouettes rather than solid colored panels.
- Decorative objects stay below the prominence of the challenge galaxy and pass touches through.

## Motion and timing

- Meteors last 1.3–2.1 seconds, satellites 10–17 seconds, and stations 18–26 seconds.
- Each event gets a stable randomized size, brightness, height, direction and path. Meteors descend diagonally from either side, with a 30–48% scene-height drop across the full offscreen-to-offscreen path; their tails align with their travel direction. Satellites retain almost-horizontal or shallow diagonal passes with at most 1.2% scene-height curvature. Stations use a gentler 1.8–3.5% curve and less endpoint drift, with their existing slowest duration range.
- Spacecraft rotation is restrained: satellites start within ±18° and rock by up to 4°; stations start within ±8° and rock by only 2°. The larger station silhouette stays steady rather than tumbling.
- The scheduler mixes 10–28, 35–65 and occasional 80–120 second quiet periods. The next type differs from the last; weighted selection favors meteors over stations.
- One environment-injected AmbientSpaceScene belongs to the app window, so navigating between pages does not restart the schedule. No global Singleton is introduced.
- Reduce Motion and inactive scene state suppress ambient movement. Returning from background schedules a fresh quiet period rather than replaying an interrupted object.

## Verification

App and embedded widget Simulator Debug build passed. Seeded regression samples cover all three kinds, both directions, timing diversity, safe parameter ranges and no immediate type repeats; existing storage/edit checks still pass.

The image below renders the actual revised event and galaxy Views at selected midpoints against a representative star field. It is a design preview, not a screenshot of the app screen or evidence of real-time animation testing. Labels identify event types only and are not added to the product.

![Event design preview](images/ambient-events-preview.png)

On-device assessment of perceived timing, brightness and movement remains useful, particularly at low screen brightness.

## Layering

Each screen uses this explicit order in its ZStack:

1. `SpaceBackground`: black field and stars.
2. `AmbientSpaceEventLayer`: decorative meteor/satellite/station.
3. Screen content: galaxies, text, controls and cards.

The first two are grouped in `SpaceSceneBackground`, placed at zIndex -1 relative to screen content. Events are not attached as a foreground overlay. The backdrop passes touches through. Transparent areas of foreground Views still reveal the backdrop naturally; opaque foreground surfaces occlude it.

## Satellite versus station silhouettes

The satellite now has a compact body, two panel wings and a small dish antenna (20–25 points wide). The station uses a long truss, four vertical panel pairs and connected modules (44–56 points wide). Their existing different motion speeds remain. Both retain the same restrained white-line material and background layering. The revised actual Views were rendered side by side and inspected; the app/widget build passed.

## Whole-scene placement follow-up

The 2026-11-03 [visual cohesion review](Visual-Cohesion.md) adds deliberate upper/middle/lower lanes, including 80–94% scene-height passes. Spacecraft reserve room for the full curve within each lane. Meteors now cross lanes on their diagonal path while remaining between 6% and 94% scene height. The same report documents detail-only editing and the matching recovery/settings treatment.

## Visibility correction after user review

The previous thin, multiply-faded strokes were too difficult to see in the delivered recording. Spacecraft now use 0.9-point outlines, higher per-event opacity and modestly larger silhouettes; meteors have a brighter 1.1-point tail/head and a 1.3–2.1s pass. Background z-order, tap pass-through, lane coverage, varied spacecraft speeds and normal quiet waits are retained. This adjustment follows the compact edit-sheet revision rather than changing completion-event or active-galaxy brightness in this task.

## Controlled motion follow-up

The motion refinement separates diagonal meteors, shallow satellite passes and slow, gently curved stations without increasing their brightness, size or appearance frequency. Seeded production-generator checks sample 512 events, including descending meteors from both sides, spacecraft curvature/tilt limits, full-path screen bounds, all three kinds, upper/lower passes and timing variation. Existing daily-use and recovery regressions pass as well.

An isolated iPhone 18 Pro simulator recording uses the actual app and event renderer with `--ambient-demo`. This deliberately selects meteor → satellite → station with shortened quiet waits; movement durations and generated paths are unchanged. Video, per-event screenshots and timestamps are kept outside the repository at `C5/artifacts/controlled-motion/`. This checks the revised visual treatment in the app; it is not a new test of the normal random waiting distribution or physical-device frame rate. Foreground content remains above events, while transparent content areas naturally reveal the background.
