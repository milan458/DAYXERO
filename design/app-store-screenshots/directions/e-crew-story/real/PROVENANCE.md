# Where the real screenshots come from

Every phone and every lifted card in Direction E shows one of these files, unedited (they are scaled down and, for the
two lifted cards, cropped in the browser; never scaled up). They were captured by the repository's UI-test CI
(`DayXeroUITests`, `JourneyUITests`) and committed to the CI device branches. Each file below is byte-identical to the
branch file named (checked with `git show origin/<branch>:<file> | cmp`).

| File here | Branch | Built from `main` commit | File on the branch | Used in |
|---|---|---|---|---|
| `day12-today.png` | `origin/ci-devices-large-light` (fa5f62d) | 6498929 | `JourneyUITeststestMaintenance-31-day12-today.png` | Frame 1 (phone peeking in) |
| `home-quitday.png` | `origin/ci-devices-large-light` (fa5f62d) | 6498929 | `JourneyUITeststestQuitDay-10-home-quitday.png` | Frame 2 |
| `home-day3.png` | `origin/ci-devices-large-light` (fa5f62d) | 6498929 | `JourneyUITeststestFirstWeekSlip-20-home-day3.png` | Frame 3 |
| `day3-program.png` | `origin/ci-devices-large-light` (fa5f62d) | 6498929 | `JourneyUITeststestFirstWeekSlip-22-day3-program.png` | Frame 4 (phone, and the lifted "Today · Day 3 · 4 cards · 3 min" row) |
| `sos-session.png` | `origin/ci-devices-large-light` (fa5f62d) | 6498929 | `JourneyUITeststestQuitDay-sos-session.png` | Frame 5 |
| `slip.png` | `origin/ci-devices-large-light` (fa5f62d) | 6498929 | `JourneyUITeststestFirstWeekSlip-21-slip.png` | Frame 6 |
| `winddown-dark.png` | `origin/ci-devices-small-dark` (6c4f404) | 2cc8b27 (the parent of 6498929) | `JourneyUITeststestEveryCalmToolOpens-50-calm-winddown.png` | Frame 7 (phone) |
| `today-later.png` | `origin/ci-devices-large-light` (fa5f62d) | 6498929 | `JourneyUITeststestWaterRowLogsEveryTap-41-water-row-after.png` | Frame 7 (the lifted "Check-in with Glim / Wind-down breath" rows) |
| `notice-the-urge.png` | `origin/ci-devices-large-light` (fa5f62d) | 6498929 | `JourneyUITeststestEveryCalmToolOpens-50-calm-noticetheurge.png` | Frame 8 (back phone) |
| `box-breathing.png` | `origin/ci-devices-large-light` (fa5f62d) | 6498929 | `JourneyUITeststestEveryCalmToolOpens-50-calm-boxbreathing.png` | Frame 8 (front phone) |
| `day12-progress.png` | `origin/ci-devices-large-light` (fa5f62d) | 6498929 | `JourneyUITeststestMaintenance-31-day12-progress.png` | Frame 9 |

Light screens: large simulator, 1320 × 2868, light mode. The one dark screen (frame 7, Glim's night) is from the small
simulator, 1170 × 2532, dark mode; no dark capture of 6498929 exists yet. 6498929 only changed `TodayPath.swift`,
`TodayView.swift` and `SessionFlowView.swift`, so the Wind down screen (`CalmToolsView`) is the same in both builds.
The lifted Today rows in frame 7 come from the light 6498929 capture for that reason. Replace `winddown-dark.png` with
the large dark capture once CI produces one.

The CI captures use the simulator clock (status bar 2:59 to 4:57 PM, Fri, Nov 20) and the UI-test persona Sam.
