# How to start a new game from this template

A checklist, top to bottom. Everything here is plain Godot / XR Tools; no
template internals need to change.

## 1. Copy the repository

```bash
git clone https://github.com/eedali/Godot-VR-Template.git my-vr-game
cd my-vr-game
bash tools/setup_vendors.sh        # OpenXR Vendors addon (needed for Quest exports)
```

Open the folder with **Godot 4.6** (any 4.6.x). The first import takes a minute.

## 2. Pick the features

1. Duplicate `res://config/vr_features_default.tres` → e.g.
   `res://config/my_game_features.tres`.
2. Project Settings → *Vr Template → Feature Config*
   (`vr_template/feature_config`) → your file.
3. Tick / untick features in the inspector. Details: [HOWTO_TOGGLE.md](HOWTO_TOGGLE.md),
   full list: [FEATURES.md](FEATURES.md).

Typical presets:

| Game type | Turn on | Turn off |
|---|---|---|
| Seated / cockpit | — | `player_body`, `direct_movement`, `teleport`, `jump`, `crouch`, `sprint`, `pockets` |
| Comfort-first exploration | `teleport`, `vignette` | `direct_movement` (teleport only), `jump` |
| Action / climbing | `climb`, `grapple`, `physical_jump` | `teleport` |
| Mixed reality (Quest) | `passthrough` | `vignette` |

Set `remove_disabled_nodes = true` once the feature set is final (disabled
nodes are then freed at startup instead of idling in the tree). Recommended
for Quest builds: a few disabled XR Tools nodes (grapple and gaze ray casts,
the wind sensor area) keep doing a little work every physics tick.

## 3. Make it yours (identity)

| What | Where | Key |
|---|---|---|
| Game name | `project.godot` | `application/config/name` (placeholder `VRStudio XR Game`) |
| Icon | `icon.png` (Godot icon today), `project.godot` | `application/config/icon` |
| Boot splash | `assets/splash/splash.png`, set on `game/main.tscn` → `LoadingScreen.splash_screen` | — |
| Windows exe metadata | `export_presets.cfg` → `[preset.0.options]` | `application/product_name`, `application/file_description`, `application/company_name`, `application/icon` |
| Android package id | `export_presets.cfg` → `[preset.2.options]` | `package/unique_name` (placeholder `com.vrstudio.xrgame` — **must** become your own reverse-domain id before any store upload) |
| Android app name / version | same | `package/name`, `version/name`, `version/code` (increase for every store upload) |
| Android icons | same | `launcher_icons/main_192x192`, `launcher_icons/adaptive_*` |
| itch.io target | `.github/workflows/publish-demo-on-push.yaml` | `BUTLER_USER_GAME` (placeholder) |

## 4. Zones and the start flow

- `game/main.tscn` is the staging scene (loading screen, StartXR). It starts at
  `game/start_scene/start_scene.tscn` (the menu).
- **New zone:** *Scene → New Inherited Scene* from `game/zones/zone_base.tscn`,
  add your content under the root, save it under `game/zones/<name>/`. The
  PlayerRig comes with the base; do not add another `XROrigin3D`.
- Create a `PersistentZoneInfo` resource next to it (`zone_id`,
  `instance_scene`) and add it to `game/zones/zone_database.tres`.
- **Starting zone:** `game/game_state.tscn` → `starting_zone`.
- Zone switches: drop `components/helpers/zone_switch_area.tscn` with a
  `CollisionShape3D`, set `zone_scene` and `spawn_node_name` (a `Marker3D` in
  the target zone).
- The showcase (`game/zones/showcase/`) and the wrist-menu *Showcase* button
  are for testing — delete them (and the button in
  `game/zones/zone_wrist_ui.tscn`) for release if you like.
- Pick-up items: inherit `components/persistent/persistent_item.tscn`, give
  each placed instance a unique `item_id`, register its type in
  `game/items/item_database.tres`.
- Save files: set `GameState` → `save_file_password` to encrypt them.

## 5. Signing and exporting

```bash
bash tools/check.sh --export                 # import + tests + Windows debug export
bash tools/godot.sh --headless --path . --install-android-build-template --quit   # once
bash tools/godot.sh --headless --path . --export-debug "Android Quest"           # build/android-quest/Game.apk
```

- **Windows (Steam/PCVR):** `--export-release "Windows"` → `build/windows/Game.exe`.
  Works with any OpenXR runtime (SteamVR, Quest Link, WMR via SteamVR). There
  is no Steamworks integration in the template.
- **Quest debug:** needs JDK 17, Android SDK 34 (`ANDROID_HOME`) and a debug
  keystore (Godot's editor settings, or the `GODOT_ANDROID_KEYSTORE_DEBUG_*`
  environment variables as the CI does).
- **Quest release / Meta Store:** create a release keystore and keep it out of
  git; set it in *Editor Settings → Export → Android* or via
  `GODOT_ANDROID_KEYSTORE_RELEASE_PATH` / `_USER` / `_PASSWORD`; switch
  `gradle_build/export_format` to AAB; export with `--export-release`.
  `gradle_build/min_sdk` (32) and `target_sdk` (34) are what the Meta store
  expects today — raise `target_sdk` when Meta requires it.

## 6. Per-platform rendering knobs

All in `project.godot`. Keys with a `.mobile` suffix apply to Android (Quest)
only; the plain key is the desktop value.

| Setting | Desktop | Quest (`.mobile`) | Notes |
|---|---|---|---|
| `rendering/renderer/rendering_method` | `gl_compatibility` | `gl_compatibility` | **Keep Quest on gl_compatibility.** PC may move to `forward_plus` in a separate branch for nicer visuals. |
| `rendering/anti_aliasing/quality/msaa_3d` | `2` (4x) | `1` (2x) | VR without MSAA shimmers badly; 4x on Quest costs ~1 ms, try it if you have budget. |
| `rendering/lights_and_shadows/directional_shadow/size` | 4096 (default) | 2048 | One shadowed directional light per zone on Quest. |
| `rendering/lights_and_shadows/positional_shadow/atlas_size` | 4096 (default) | 1024 | Avoid shadowed omni/spot lights on Quest. |
| `xr/openxr/foveation_level` / `foveation_dynamic` | 3 / on | same | Fixed foveated rendering (Quest). |
| `target_refresh_rate` (feature config) | 0 | 72 / 90 / 120 | Applied by StartXR when the session starts. |
| `physics_rate_multiplier` (feature config) | 1 | 1 | Physics ticks per frame; 2 helps fast hand physics at 72 Hz. |
| `xr/openxr/extensions/hand_tracking` (+ `hand_interaction_profile`) | on | on | Controller-free hands; the `hand_tracking` toggle hides them per game. |

Budget rules of thumb for Quest 3 in `gl_compatibility`: no SDFGI, SSR, SSAO
or volumetric fog; keep `Viewport2DIn3D` panels throttled (≤ 15 fps); prefer
`Label3D` for world text; ≤ 2 shadow casters per zone.

## 7. Before you ship

- `bash tools/check.sh --run --export` passes.
- `debug_hud` is ignored in release builds automatically; remove the wrist
  *Showcase* button.
- Test on a headset: the list in `docs/claude/PROGRESS.md` ("Needs headset
  test") is a good script.
- Update `README.md` and `docs/CHANGELOG.md`.
