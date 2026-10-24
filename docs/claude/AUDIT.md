# Audit — state of the repo at commit `9cedf32` (2026-10-24)

Reviewed by Claude (chat) from a clone of `eedali/Godot-VR-Template@main`.
Items marked **CONFIRMED** were read in the source. Items marked **VERIFY**
are strongly suspected; confirm in the editor/headless run before fixing.
Fix everything in this file in Phase 1 unless a later phase explicitly owns it.

## A. Bugs / correctness

| # | Where | Finding | Fix |
|---|---|---|---|
| A1 | `components/persistent/persistent_zone.gd` `scene_exiting()` | **CONFIRMED.** Comment says "Clear the current zone" but the code assigns `GameState.current_zone = self`. After the zone is freed `GameState.current_zone` dangles; `GameState.save_world_state()` only checks `not current_zone`, not `is_instance_valid`. | Set `current_zone = null` **after** `save_world_state()`; in `game_state.gd` guard with `is_instance_valid(current_zone)` everywhere `current_zone` is used. |
| A2 | `game/game_state.gd` `load_world_state()` | **CONFIRMED.** `game_difficulty = get_value("game_difficulty")` assigns `null` when the key is missing (older save files) → setter gets `null` for an `int`-typed enum → runtime error. | `get_value("game_difficulty", GameDifficulty.GAME_NORMAL)` and validate type before assigning. |
| A3 | `game/game_state.gd` `_set_game_difficulty()` | **CONFIRMED.** Setter writes to `_data` via `set_value()` during `_ready`/scene load — harmless, but it also runs in the editor through `@export` inspection paths of autoloads. Also `quit_game()` dereferences `current_zone` without validity check. | Guard with `is_instance_valid`; keep behaviour. |
| A4 | `game/start_scene/start_ui.gd` | **CONFIRMED.** Debug `print()` calls left in; `_set_pane()` uses magic numbers 1–4. | Remove prints, use an enum for panes. |
| A5 | `components/helpers/zone_switch_area.gd` | **CONFIRMED.** Uses legacy `connect("body_entered", Callable(self, ...))` inside a `@tool` script, so it also connects in the editor. | Use `body_entered.connect(_on_body_entered)` and skip in `Engine.is_editor_hint()`. |
| A6 | `game/**/*.tscn`, `components/**/*.tscn|.tres` | **CONFIRMED (low).** All `.gd.uid` files *are* committed, but 25 `ext_resource type="Script"` references are path-only (no `uid=`), unlike the XR Tools scenes. Works; a rename would break them. | Optional: re-save scenes headless (`GODOT_NOTES.md §4`) and keep the diff only if it is limited to `uid=` additions. Otherwise skip. |
| A7 | `game/zones/*/..._zone_info.tres` | **CONFIRMED.** Header says `script_class="ZoneInfo"` but the script's `class_name` is `PersistentZoneInfo`. Editor-only metadata, but stale. | Re-save or edit the header to `PersistentZoneInfo`. |
| A8 | `game/zones/*_zone.tscn` | **CONFIRMED.** Each zone scene carries the full hand rig (blend trees, bone overrides) copied from `zone_base.tscn` because the rig is inline in the base scene. Three near-identical 400-line blocks → any rig change must be repeated per zone. | Owned by Phase 3 (`PlayerRig` refactor): zones instance one rig scene. |

## B. Claims in README that the project does not deliver

| # | Finding | Fix |
|---|---|---|
| B1 | README says "Try teleport" — **CONFIRMED** there is no `function_teleport` / `teleport_area` anywhere in `game/` or `components/`. | Phase 3/4 adds teleport (toggle `teleport`). |
| B2 | README says "hand tracking and passthrough" — **CONFIRMED** (probed with Godot 4.6-stable: `xr/openxr/extensions/hand_tracking = false`, `hand_interaction_profile = false`, `environment_blend_mode = 0`): the project does not enable the hand-tracking extension and nothing enables passthrough (`StartXR.enable_passthrough` is `false`, blend mode untouched). Only the Android export flags are set, which is not enough. | Phase 4: enable `xr/openxr/extensions/hand_tracking=true` (+ `hand_interaction_profile`), add a `PassthroughController` that sets `XRInterface.environment_blend_mode` to alpha-blend and `viewport.transparent_bg`, driven by the feature config. |
| B3 | Start menu "Options" pane is **CONFIRMED empty** (only a Back button). `XRToolsUserSettingsUI` exists in the addon but is unused. | Phase 5: embed `addons/godot-xr-tools/user_settings/user_settings_ui.tscn` in the Options pane. |
| B4 | README "Folder structure" says XR Tools **4.5.1**, `plugin.cfg` says **4.5.2**; `VERSIONS.md` top entry still says 4.5.1. | Phase 7 docs. |
| B5 | README calls the Windows preset "SteamVR-compatible"; true for OpenXR but no Steamworks integration exists (README does say so further down). Keep it honest. | Phase 7 docs. |

## C. Project settings & exports

| # | Finding | Fix |
|---|---|---|
| C1 | `export_presets.cfg` Windows/Linux/Android `exclude_filter` reference `addons/godot-openxr/bin/...` — a plugin path from Godot 3 that does not exist. Harmless, confusing. | Remove the stale filters. |
| C2 | Android preset: `package/unique_name="com.vrstudio.xrgame"`, product names "VRStudio XR Game" — placeholders. | Keep as placeholder but make it obvious: document in `docs/HOWTO_NEW_GAME.md` the exact keys to change (Phase 7). Do **not** invent a real package name. |
| C3 | `application/config/name="VRStudio XR Game"` placeholder; `icon.png` is the Godot icon; splash is upstream's. | Same as C2 — document, do not replace art. |
| C4 | `xr/openxr/foveation_level=3` + dynamic is set globally; `rendering/anti_aliasing/quality/msaa_3d` is **0 (off)** on every platform (probed), and there is no per-platform tuning of MSAA / shadows / scaling. VR without MSAA aliases badly. | Phase 6: add `.mobile` feature-tagged overrides (`rendering/anti_aliasing/quality/msaa_3d.mobile`, shadow sizes) and keep desktop a notch higher. |
| C5 | `physics/3d/physics_engine="GodotPhysics3D"` with `contact_max_allowed_penetration=0.001` — upstream choice for XR Tools; keep. | None. |
| C6 | No `xr/openxr/extensions/hand_tracking`, no `hand_interaction_profile`, no `eye_gaze_interaction` (fine for Quest 3, no eye tracking). | B2. |
| C7 | `.gitignore` ignores `build/*/*` per platform but not `build/claude-logs/`. | Phase 0: append `build/claude-logs/` and `.claude/settings.local.json`. |

## D. CI / tooling

| # | Finding | Fix |
|---|---|---|
| D1 | `publish-demo-on-push.yaml` runs `godot ... --export-... \|\| exit 0` — **export failures never fail the job**. Same for the import step. | Keep import tolerant; make the export step fail on error and also fail when the expected output file is missing. |
| D2 | `GODOT_VERSION: 4.6.1` in CI vs local editor **4.6 stable** and `config/features=("4.6")`. **VERIFY** that `4.6.1` exists on GitHub releases (`godotengine/godot-builds`); if not, set CI to `4.6-stable`. Either way the local editor and CI should agree in the README. | Phase 6. |
| D3 | `gdlint-on-push.yml` lints only `components/`; `game/` is never linted; `setup-python@v4` is old. | Lint `components game tools`; bump to `setup-python@v5`; add a `.gdlintrc` generated with `gdlint --dump-default-config` and tuned so the current XR-Tools-style code passes (tabs, `##` comments). |
| D4 | CI uses `BUTLER_USER_GAME: godot-xr/godot-xr-template` (upstream's itch.io target). Pushing a tag with `BUTLER_API_KEY` set would try to publish to upstream's game. | Change to `eedali/godot-vr-template` placeholder and comment it clearly. |
| D5 | No `.editorconfig`, no `CLAUDE.md` (now added), no tests. | This package adds `.editorconfig`; `tools/smoke_test.gd` is the first automated test. |

## E. Architecture gaps (why the template is not yet "comprehensive")

1. **No single place to turn features on/off.** Mechanics are hard-wired as
   nodes inside `zone_base.tscn`. → `VRFeatureConfig` + `PlayerRig` (Phase 2–3).
2. **Only 7 of ~25 XR Tools mechanics are wired in** (direct move + strafe,
   turn, jump, crouch, sprint, pickup, pointer, poke). Missing: teleport, climb,
   flight, glide, grapple, wall-walk, world-grab, jog, physical jump, footsteps,
   wind, gaze pointer, vignette, fade, snap zones demo, interactables (button,
   area button, handle, hinge, slider, joystick), climbable, virtual keyboard,
   hand-pose areas, surface/area/pickable audio, return-to-snap-zone, teleport
   areas, world-grab areas. See `FEATURES.md`.
3. **No comfort layer** (vignette on turn/move, fade on scene switch is only the
   staging one).
4. **No haptics helper** (XR Tools has `XRToolsRumbleManager` autoloaded but nothing calls it).
5. **No debug/profiling HUD** for Quest frame budget work.
6. **No "how to make a new game from this" document** and no showcase scene.

## F. Things that are fine — leave alone

- XR Tools 4.5.2 is the current stable series; do not downgrade/upgrade.
- `gl_compatibility` on both desktop and mobile is deliberate (Quest).
- The persistence system (`PersistentWorld/Zone/Item/Pocket`) is sound; extend,
  don't rewrite.
- `openxr_action_map.tres` is upstream's full map; only add actions if a new
  feature needs them.
