# Decisions log

Instead of asking the user, Claude Code records each judgement call here.
One entry per decision. Newest at the bottom.

Format:

```
### D-<n> — <short title>   (<phase>, <date>)
Context: what was ambiguous
Decision: what was chosen
Alternatives: what else was considered and why it lost
Reversible: yes/no — how
```

### D-0 — Defaults chosen before work started (planning, 2026-10-24)
Context: the user asked for a template with every feature available and easy
to switch off, no questions during execution.
Decision: toggles live in a single `VRFeatureConfig` resource; the default
config reproduces today's behaviour plus teleport, vignette, haptics,
hand-tracking and desktop fallback; "exotic" locomotion (climb, flight, glide,
grapple, wall-walk, world-grab, jog, physical jump, wind, footsteps) ships off.
Alternatives: ProjectSettings-only toggles (no inspector grouping, no per-game
copies); per-zone exports (duplicated config). Both lost to the resource.
Reversible: yes — edit `config/vr_features_default.tres`.

### D-1 — `setup_vendors.sh` install check   (phase 0, 2026-10-24)
Context: the script tested for `addons/godotopenxrvendors/plugin.cfg`, but the
4.3.0 addon is a GDExtension with `plugin.gdextension` and no `plugin.cfg`, so
it re-downloaded and replaced the (identical) addon on every run.
Decision: check for `plugin.gdextension`; print the version from the addon's
CHANGES file.
Alternatives: leave it (wasteful, deletes the folder each run).
Reversible: yes — one line in `tools/setup_vendors.sh`.

### D-2 — `--xr-mode off` for every project run in checks   (phase 0, 2026-10-24)
Context: `xr/openxr/enabled=true`; running the project headless without an HMD
makes Godot show a modal "OpenXR was requested but failed to start" alert on
Windows (the user reported it during the baseline run).
Decision: `tools/check.sh` passes `--headless --xr-mode off` to the smoke test
and the headless run; docs updated. `xr/openxr/startup_alert` stays at its
default (true) so real players still learn why VR did not start.
Alternatives: set `xr/openxr/startup_alert=false` project-wide (hides a useful
message from players and testers with a misconfigured runtime).
Reversible: yes — remove `--xr-mode off` from `RUN_FLAGS`.

### D-3 — Normalise `export_presets.cfg` line endings   (phase 1, 2026-10-24)
Context: the committed file had `CR CR LF` line endings (git stored it as
binary, `-text`), so any text tool edit produced a whole-file diff.
Decision: strip every `CR` (LF only, as `.gitattributes` asks) in the same
commit that removes the stale Godot 3 `exclude_filter` values (AUDIT C1).
`git diff -w` shows only the three filter lines.
Alternatives: keep the broken endings (every later edit would be unreadable).
Reversible: yes — git history.

### D-4 — Skip the headless scene re-save (A6)   (phase 1, 2026-10-24)
Context: GODOT_NOTES §4 suggests re-saving scenes from a `--script` run to add
`uid=` to path-only `ext_resource` lines.
Decision: tried it; `ResourceSaver.save` in a SceneTree script **dropped** every
existing `uid=` (including the scenes' header uids) and rewrote typed arrays.
Reverted with `git checkout -- game components`, removed the helper script,
marked 1.5 `[~]`. Path-only references keep working; the editor adds uids the
next time a scene is saved by hand.
Alternatives: hand-add uids (error-prone; GODOT_NOTES says never hand-write uids).
Reversible: n/a.

### D-5 — Fix the `script_class` header of the item-type resources too   (phase 1, 2026-10-24)
Context: AUDIT A7 named the three `*_zone_info.tres`; the four
`game/items/*/*_type.tres` had the same stale header (`ItemType` vs
`PersistentItemType`).
Decision: fixed all seven headers.
Reversible: yes.

### D-6 — `head_behavior` instead of `head_fade`   (phase 2, 2026-10-24)
Context: FEATURES.md named the head-in-wall toggle `head_fade`, while
ARCHITECTURE.md and PLAN 4.2 use `head_behavior` with the three XR Tools modes
(Push away / Fade / Disabled).
Decision: one setting, `head_behavior` (int enum mirroring
`XRToolsPlayerBody.head_behavior_mode`); FEATURES.md updated. A bool cannot
express three modes.
Alternatives: both names (two switches for one thing).
Reversible: yes.

### D-7 — `VRFeatures` API details   (phase 2, 2026-10-24)
Context: ARCHITECTURE §2 sketches `feature_changed(name, enabled : bool)` but
some settings are ints/enums (`turn_mode`, `head_behavior`,
`target_refresh_rate`, `physics_rate_multiplier`).
Decision: keep `feature_changed` for bool toggles and add
`value_changed(feature, value)` emitted for every change (rigs listen to this
one) plus `set_value()`; values are `type_convert`ed to the setting's type.
The config is loaded in `_init` (not `_ready`) so other autoloads/scenes can
query it from their own `_ready`. The project setting
`vr_template/feature_config` is written to `project.godot` (discoverable in
Project Settings) and still read with a default.
Alternatives: a Variant-typed `feature_changed` (breaks the documented
signature).
Reversible: yes.

### D-8 — `loading_prompt` semantics   (phase 2, 2026-10-24)
Context: today the first scene load shows "hold to continue" and
`GameStaging` clears `prompt_for_continue` after it. ARCHITECTURE defaults
`loading_prompt` to false.
Decision: `loading_prompt = true` keeps the prompt on every load;
false (default) is today's behaviour (first load only).
Reversible: yes.

### D-9 — `collision_hands` off = XR Tools TELEPORT mode, no re-parenting   (phase 3, 2026-10-24)
Context: ARCHITECTURE §3 suggested re-parenting the hand subtree under the
controller when collision hands are off.
Decision: `XRToolsCollisionHand` already has `mode` (DISABLED / TELEPORT /
COLLIDE); off sets `TELEPORT` (the body snaps to the controller every physics
frame instead of sliding along walls), on restores `COLLIDE`. (Correction
after review: the hand body keeps its collision layer in TELEPORT mode, so it
can still push light rigid bodies; see D-15 for the layers.) No node moves, so every
`FEATURE_NODES` path stays valid and the toggle works at runtime.
Alternatives: re-parent (breaks node paths, persistence lookups and runtime
re-enable).
Reversible: yes.

### D-10 — Hand models renamed `LeftHandModel` / `RightHandModel`   (phase 3, 2026-10-24)
Context: in zone_base the hand mesh instance under `CollisionHandLeft` was
also called `LeftHand`, giving paths like `LeftHand/CollisionHandLeft/LeftHand`.
Decision: rename to `LeftHandModel` / `RightHandModel` (as ARCHITECTURE §3
draws it). Nothing looked the mesh up by name (XR Tools searches by class).
Reversible: yes.

### D-11 — `hand_models` off hides the mesh and stops its AnimationTree only   (phase 3, 2026-10-24)
Context: the poke and the collision-hand finger shapes live under the hand
model's skeleton; `process_mode = DISABLED` on the model would freeze them.
Decision: special handler: `visible = false` + `AnimationTree.active = false`;
the node keeps processing. `remove_disabled_nodes` never frees hand models or
the player body (`NEVER_FREE`; GameState needs the body to save).
Reversible: yes.

### D-12 — Headless zone-load test added to `check.sh --run`   (phase 3, 2026-10-24)
Context: PLAN 3.6 asks to confirm the start menu → zone path has no script
error; `--quit-after` on the main scene never leaves the start menu.
Decision: `tools/zone_load_test.gd` drives the real flow (presses continue,
`GameState.new_game()`, loads every zone in the database, toggles a feature at
runtime, saves) and is part of `--run`. It is duck-typed because `--script`
compiles it before autoloads are registered.
Reversible: yes — drop the block from `tools/check.sh`.

### D-13 — Haptics are triggered by the rig, not by PersistentItem   (phase 4, 2026-10-24)
Context: PLAN 4.4 says to call `Haptics` from `PersistentItem` pick-up/drop and
from pointer presses.
Decision: the rig connects every `FunctionPickup.has_picked_up/has_dropped`
and every `FunctionPointer.pointing_event` (PRESSED) to `Haptics.tap/pulse`.
This covers every pickable (PersistentItem included) and every pointer
without touching item scripts; `Haptics` checks the `haptics` toggle itself.
Alternatives: hooks in `PersistentItem` (misses non-persistent pickables,
double pulses with the rig hook).
Reversible: yes.

### D-14 — `hand_tracking` toggle semantics   (phase 4, 2026-10-24)
Context: PLAN 4.6 says "rig sets show_when_tracked from the toggle", but
`show_when_tracked` only hides an untracked controller; it cannot tell hands
from controllers. XR Tools hands are animated from trigger/grip values, so
controller-free hands work once the runtime maps pinch/grasp to those actions.
Decision: project settings enable `hand_tracking`, both hand-tracking data
sources and `hand_interaction_profile`; `openxr_action_map.tres` gains an
`/interaction_profiles/ext/hand_interaction_ext` profile (pinch -> trigger /
trigger_click, grasp -> grip / grip_click, aim/grip poses). The toggle: on =
hands may drive the controllers (default); off = a controller whose profile
switches to the hand-interaction profile is hidden and stops processing
(`XRController3D.profile_changed`, no polling). `show_when_tracked` stays true.
Needs a headset test.
Alternatives: XRHandModifier3D skeleton tracking (the XR Tools low-poly hands
use a different bone layout; out of scope).
Reversible: yes.

### D-15 — Collision hands on the XR Tools layers   (phase 4, 2026-10-24, review finding)
Context: the reviewer found `CollisionHandLeft/Right` (copied from main) had no
`collision_layer`/`mask`, so they sat on layer 1 and the player body (mask
1023) collided with its own hands.
Decision: use the XR Tools collision-hand scene values: layer 18 "Player
Hands" (131072), mask 262175 (layers 1-5 + 19). Behaviour change vs main; on
the headset-test list.
Reversible: yes.

### D-16 — Feature rules inside the rig   (phase 4, 2026-10-24, review findings)
Decision:
- `remove_disabled_nodes` frees nodes in the rig's `_enter_tree` (children not
  yet in the tree, so the player body never caches them); `player_body`,
  `pickup`, `pockets` are never freed (GameState / persistence need them).
- `player_body = false` forces every body-driven movement feature and the hip
  pockets off and logs one warning (zone-switch areas need the body as well).
- `flight` on -> left-hand crouch off (both use B/Y).
- Left teleport pauses while the left pointer is on a target or the left hand
  holds something (all three use the left trigger).
- Switching `pickup` off drops held objects; switching `crouch` off clears the
  crouch height override; `height_calibration` (one-shot) is only applied at
  startup or when it changes; `has_feature()` only accepts exported settings.
- Held items restored on zone load only attach to an enabled pickup, otherwise
  they drop at the hand as zone items.
Reversible: yes.

### D-17 — Staging-level settings applied by GameStaging   (phase 4, 2026-10-24)
Context: `target_refresh_rate`, `physics_rate_multiplier` and `loading_prompt`
must be in place before the first zone (the start scene has no rig).
Decision: `game/main.gd` forwards the rates to `StartXR` in `_ready` (before
the OpenXR session begins) and re-applies them at runtime; it also owns
`loading_prompt`. The rig lists them in `EXTERNAL_FEATURES`, and the smoke
test fails if any config setting is handled nowhere.
Reversible: yes.

### D-18 — Desktop fallback: runtime input actions, deferred instancing   (phase 4, 2026-10-24)
Context: the XR Tools desktop nodes default to actions that do not exist in
this project (`action_crouch`, `action_sprint`, `trigger_click` as an InputMap
action) and the pointer/hiders must live under the camera/controllers.
Decision: `DesktopFallback` registers `desktop_*` actions (WASD/arrows, Space,
C/Ctrl, Shift, left mouse) at runtime if missing, creates the pointer and the
controller hiders in the right places, and the rig instances it (deferred)
only when `XRServer.primary_interface` is null, then refreshes the player
body's cached provider list.
Reversible: yes.

### D-19 — Debug HUD shows memory instead of battery   (phase 4, 2026-10-24)
Context: ARCHITECTURE §5 asked for `OS.get_power_percent_left()`; it does not
exist in Godot 4.6 (probed with ClassDB).
Decision: show FPS, frame/physics time, draw calls, physics rate and static
memory; documented.
Reversible: yes.

### D-20 — `persistent_zone.tscn` rebuilt; `zone_base.tscn` inherits it   (phase 4, 2026-10-24, review finding)
Context: the reviewer noted `components/persistent/persistent_zone.tscn` still
inherited XR Tools `scene_base.tscn` (bare origin, no rig) and was unused.
Decision: it is now the generic zone root (Node3D + `persistent_zone.gd` +
PlayerRig as `XROrigin3D`); `game/zones/zone_base.tscn` inherits it so a game
can add what all its zones share. Node paths and indices of the demo zones are
unchanged.
Reversible: yes.

### D-21 — Zone-side toggles through `FeatureGate`   (phase 4, 2026-10-24)
Context: `virtual_keyboard` (and any zone content a game wants to tie to a
toggle) lives in zones, not on the rig.
Decision: `components/system/feature_gate.gd` — a child node that hides and
disables its parent (process mode, so bodies/areas leave the physics
simulation) while a feature is off, following runtime changes. Climbable
walls, teleport/world-grab/wind areas are not gated: without their movement
provider they are inert scenery.
Reversible: yes.

### D-22 — Showcase helpers: FeatureStatusLabel and FeatureToggleButton   (phase 5, 2026-10-24)
Context: the showcase must show every mechanic, but most exotic ones ship off,
and the comfort kiosk needs passthrough / debug-HUD toggle buttons.
Decision: each station has a `FeatureStatusLabel` (Label3D listing the live
on/off state of its toggles, signal-driven); kiosk buttons are the
`push_button` prefab plus a `FeatureToggleButton` node that flips a feature
through `VRFeatures`. Both are reusable components in `components/system/`.
The showcase spawns players at `FromAnywhere`; its portal returns to Outside
at that zone's default spawn. The wrist menu "Showcase" button is meant for
testing and documented as removable.
Reversible: yes.

### D-23 — CI Godot version stays 4.6.1   (phase 6, 2026-10-24)
Context: AUDIT D2 asked to verify `GODOT_VERSION: 4.6.1` exists, else use
4.6-stable, and to make README and CI agree. The local editor is 4.6-stable.
Decision: `4.6.1-stable` exists on godotengine/godot-builds (published
2026-02-16; 4.6.3 is the newest 4.6 patch), so CI keeps 4.6.1 (a bug-fix
release of the same feature level the project targets, `config/features=4.6`).
README states: local 4.6-stable or any 4.6.x works, CI builds with 4.6.1.
Alternatives: pin CI to 4.6.0 to equal the local editor (loses bug fixes);
bump to 4.6.3 (untested here).
Reversible: yes — one line in the workflow.

### D-24 — CI exports fail loudly; Android CI gets a throw-away debug keystore   (phase 6, 2026-10-24)
Context: the export step ended in `|| exit 0`, so a broken export never failed
CI (AUDIT D1). Making it strict would turn the Android job red because CI has
no debug keystore configured.
Decision: the export step removes the expected output first, fails on Godot's
non-zero exit (the runner shell uses `-e -o pipefail`), on an
"ERROR: Project export/Cannot export/Failed to export" line, or on a missing
output file (`export-file` per matrix entry). The Android job generates a
debug keystore with `keytool` and passes it through Godot's documented
`GODOT_ANDROID_KEYSTORE_DEBUG_*` variables. The import step stays tolerant.
Reversible: yes.

### D-25 — Quest render settings   (phase 6, 2026-10-24)
Decision: `msaa_3d=2` (4x) desktop, `msaa_3d.mobile=1` (2x) Quest as PLAN 6.1
says; `directional_shadow/size.mobile=2048` (written explicitly, equals the
engine default) and `positional_shadow/atlas_size.mobile=1024` (engine default
2048) to save Quest memory. Knobs documented in docs/HOWTO_NEW_GAME.md §6.
Reversible: yes.
