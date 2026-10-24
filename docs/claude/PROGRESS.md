# Progress log

Maintained by Claude Code while executing `PLAN.md`. Keep it short and factual;
every "done" must name the log file or command that proved it.

## Phase status

| Phase | Status | Commit(s) | Check log | Notes |
|---|---|---|---|---|
| 0 Setup & baseline | done | ae0cb83, (this) | `build/claude-logs/` baseline above | gdlint present; vendors 4.3.0 installed |
| 1 Audit fixes | todo | | | |
| 2 Feature config | todo | | | |
| 3 PlayerRig refactor | todo | | | |
| 4 Mechanics & components | todo | | | |
| 5 Showcase & menu | todo | | | |
| 6 Platform / export / CI | todo | | | |
| 7 Docs | todo | | | |
| 8 Final verification & push | todo | | | |

Status values: `todo` · `in progress` · `done` · `blocked (<reason>)` · `partial (<what is missing>)`

## Baseline (Phase 0.5)

`bash tools/check.sh --run` on `ae0cb83` (2026-10-24, Godot 4.6.stable.official.89cea1439,
gdlint 4.5.0, Python 3.12.10), before any game-code change:

| Step | Result | Notes |
|---|---|---|
| Import | PASS | `build/claude-logs/import.log` |
| Smoke test | PASS | 51 files checked, 0 failures (`smoke.log`) |
| gdlint | **FAIL** | 2 problems: `game/game_state.gd:63` trailing whitespace; `game/start_scene/start_ui.gd:4` class-definitions-order (`gdlint.log`) |
| Headless run | PASS | no `SCRIPT ERROR` (`run.log`) |

Known noise in run/smoke logs (not regressions): OpenXR init failure (no HMD),
`Property not found: 'xr/openxr/extensions/hand_tracking'` (setting absent from
project.godot; Phase 4.6 adds it), `Viewport Texture must be set to use it`
(XR Tools `Viewport2DIn3D` instantiated outside the tree), `graph_offset property
is deprecated` (upstream visual shader), `ObjectDB instances leaked at exit`.

The first baseline run (without `--xr-mode off`) popped up a blocking Windows
"OpenXR was requested but failed to start" alert on the user's screen; the check
script now passes `--xr-mode off` to every step that runs the project (D-2).

## Blockers

_None yet._

## Needs headset test

_Append one line per item: feature — what to do on the Quest 3 — what to expect._

## Push log

_Date/time — branch — result (ok / auth failed / network)._
