# Progress log

Maintained by Claude Code while executing `PLAN.md`. Keep it short and factual;
every "done" must name the log file or command that proved it.

## Phase status

| Phase | Status | Commit(s) | Check log | Notes |
|---|---|---|---|---|
| 0 Setup & baseline | done | ae0cb83, (this) | `build/claude-logs/` baseline above | gdlint present; vendors 4.3.0 installed |
| 1 Audit fixes | done | d15845b, (this) | `bash tools/check.sh --run` → ALL CHECKS PASSED (`build/claude-logs/run.log`) | A6 skipped (`[~]`, D-4); gdlint now clean |
| 2 Feature config | done | (this) | `bash tools/check.sh --run` → ALL CHECKS PASSED; smoke log `VRFeatureConfig exposes 44 settings`; headless probe: `VRFeatures.is_enabled(&"teleport") == true`, `set_value(&"teleport", 0)` → false, unknown name → warning | 44 settings |
| 3 PlayerRig refactor | done | 8879e3e, (this) | `bash tools/check.sh --run` → ALL CHECKS PASSED incl. new `tools/zone_load_test.gd` (start scene → new game → all 3 zones, runtime toggle, save) `build/claude-logs/zones.log`; startup toggle proven with a temporary `direct_movement = false` config (`zones-direct-off.log`: `VRFeatures: direct_movement -> off (MovementDirect)` ×2 at zone load) | see node counts below |
| 4 Mechanics & components | done | (this) | `bash tools/check.sh --run` -> ALL CHECKS PASSED: smoke (43 rig paths, every setting handled), zone test x3 (default / `--set=all_on` / minimal + `remove_disabled_nodes`) in `build/claude-logs/zones*.log`; passthrough without XR -> only `WARNING: PassthroughController: no active XR interface` | review findings 1-8 fixed |
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

## Phase 3 — zone node counts (3.5)

`grep '^\[node'` before (HEAD~) / after the rewrite. Every dropped node was a
rig override (`parent="XROrigin3D/..."`: 2× Skeleton3D bone poses,
2× BoneAttachment3D transforms, 2× AnimationTree blend-tree copies, identical
to the rig's own values); the list of content nodes is byte-identical
(`diff` of the non-rig `[node` lines is empty).

| Zone | nodes before | nodes after | rig overrides dropped | lines before → after |
|---|---|---|---|---|
| outside_zone.tscn | 48 | 42 | 6 | 328 → 208 |
| house_interior_zone.tscn | 87 | 81 | 6 | 515 → 395 |
| house_back_yard_zone.tscn | 41 | 35 | 6 | 292 → 172 |
| zone_base.tscn | 47 (rig inline) | 2 (root + rig instance) | — | 281 → 9 |

## Blockers

_None yet._

## Needs headset test

_Append one line per item: feature — what to do on the Quest 3 — what to expect._

- hand tracking — put the controllers down, raise both hands — hands follow, pinch clicks UI / starts the left teleport, grasp picks up; with `hand_tracking = false` the hands disappear instead
- passthrough — set `passthrough = true` (or toggle at runtime) — camera feed replaces the sky, zone geometry stays; `false` restores the sky
- teleport — hold the left trigger away from UI — arc visible in gl_compatibility, release teleports; trigger on a UI panel clicks without teleporting
- vignette — smooth-turn and walk — tunnel fades in while moving, out when still; `vignette_auto_adjust = false` gives a permanent 0.8 tunnel
- collision hands (now layer 18) — push the hands into a wall/table, reach for hip/back pockets — hands stop at surfaces, the body no longer bumps into its own hands
- collision hands off — `collision_hands = false` — hands follow the controllers exactly and pass through walls
- climb + world grab + collision hands — enable `climb`/`world_grab`, use the showcase wall/area — grabbing pulls the player, hands do not jitter
- flight — `flight = true`, press left B/Y — toggles flying; left crouch does nothing, right crouch still works
- refresh rate — `target_refresh_rate` 72 / 90 / 120 — headset switches rate (log: "StartXR: Setting refresh rate to ...")
- haptics — pick up / drop an item, press a UI button — short tick on that controller; `haptics = false` silences it
- debug HUD — `debug_hud = true` in a debug build — panel below the view shows FPS/frame time; absent in a release export

## Push log

_Date/time — branch — result (ok / auth failed / network)._
