# Changelog

Changes of this template on top of the upstream
[godot-xr-template](https://github.com/GodotVR/godot-xr-template) history in
[VERSIONS.md](../VERSIONS.md).

## Unreleased — template overhaul (branch `claude/template-overhaul`, 2026-10-24)

### Added
- **One feature config.** `config/vr_feature_config.gd` (`VRFeatureConfig`,
  44 settings) + `config/vr_features_default.tres`, selected by the project
  setting `vr_template/feature_config`. The `VRFeatures` autoload loads it,
  works on a copy and broadcasts runtime changes. See `docs/HOWTO_TOGGLE.md`.
- **PlayerRig** (`components/player/player_rig.tscn/.gd`): the whole player in
  one scene, driven by the config. Every XR Tools mechanic is wired in:
  teleport, physical jump, jog, climb, flight, glide, grapple, wall walk,
  world grab, wind, footsteps, vignette, gaze pointer, hand-pose detectors,
  plus the existing movement, hands, pointer, poke, pockets and wrist menu.
  Rules between features (movement needs the player body, flight vs. left
  crouch, teleport pauses while the left trigger is used for UI or holding).
- Components: `Haptics` helper + tap preset, `PassthroughController`,
  `DebugHUD`, `DesktopFallback` (keyboard/mouse with runtime input actions),
  `FeatureGate`, `FeatureToggleButton`, `FeatureStatusLabel`.
- Prefabs: `components/interactables/` (push button, lever, slider, joystick,
  snap zone, hand-pose area, virtual keyboard) and `components/locomotion/`
  (teleport pad, climbable wall, grapple target, wall-walk surface, world-grab
  area, wind area).
- **Showcase zone** (`game/zones/showcase/`) with five labelled stations,
  reachable from the start menu (New Game → Showcase) and the wrist menu.
- Start menu Options pane: XR Tools user settings UI (snap turning, dead
  zones, haptics, height).
- Controller-free hand tracking: OpenXR hand tracking + hand interaction
  profile enabled; the action map maps pinch / grasp to trigger / grip.
- Per-platform rendering: MSAA 4x desktop / 2x Quest, Quest shadow atlas sizes.
- Tooling: `tools/check.sh` (import, smoke test, gdlint, headless run,
  game-flow test with three feature configs, Windows export),
  `tools/smoke_test.gd`, `tools/zone_load_test.gd`, `tools/setup_vendors.sh`,
  `.gdlintrc`, `.editorconfig`.
- Docs: `docs/FEATURES.md`, `docs/HOWTO_TOGGLE.md`, `docs/HOWTO_NEW_GAME.md`,
  this changelog; README rewritten.

### Changed
- Zones no longer copy the rig: `components/persistent/persistent_zone.tscn`
  is a plain zone root with the PlayerRig, `game/zones/zone_base.tscn`
  inherits it and the demo zones keep only their content.
- Collision hands use the XR Tools layers (18 "Player Hands", mask 1-5 + 19)
  instead of layer 1, so the player body no longer collides with its own hands.
- Hand meshes are named `LeftHandModel` / `RightHandModel`.
- CI: exports fail on errors / missing output, the Android job creates a
  debug keystore, the itch.io target is an `eedali/...` placeholder, gdlint
  covers `components config game tools` with setup-python v5.

### Fixed
- `PersistentZone` left `GameState.current_zone` pointing at a freed zone.
- Loading a save without `game_difficulty` assigned `null` to an enum.
- `GameState` used `current_zone` without validity checks.
- Start menu debug prints and magic pane numbers; zone switch areas connected
  in the editor; stale `script_class` headers in zone/item resources; stale
  Godot 3 export filters; `CR CR LF` line endings in `export_presets.cfg`.
- Held items restored into a disabled pickup could never be dropped.

### Versions
- Godot 4.6 (CI 4.6.1), Godot XR Tools **4.5.2**, OpenXR Vendors 4.3.0-stable.
