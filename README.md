# Godot VR Template

A starting point for **many different VR games** on **Godot 4.6** with
**OpenXR** — Meta Quest 3 first, PC VR (SteamVR / any OpenXR runtime) second.
Built on [Godot XR Tools 4.5.2](https://github.com/GodotVR/godot-xr-tools) and
the upstream [godot-xr-template](https://github.com/GodotVR/godot-xr-template).

Every common VR mechanic is already wired into one player rig and can be
switched on or off from **one config file** — start a new game by ticking
boxes, not by rebuilding the player.

| Target | Status |
|---|---|
| Meta Quest 3 (APK) | builds (CI + local); on-device test list in [docs/FEATURES.md](docs/FEATURES.md#needs-a-headset-test) |
| PC VR, Windows (OpenXR: SteamVR, Quest Link, ...) | builds; runs headless in CI-style checks |
| Linux, WebXR | build in CI |
| Desktop without headset | keyboard / mouse fallback |

Versions: **Godot 4.6** (local editor 4.6-stable; CI builds with 4.6.1 — any
4.6.x opens the project), **XR Tools 4.5.2** (in `addons/`), **OpenXR Vendors
4.3.0-stable** (downloaded, not in git), JDK 17, Android SDK 34 / min 32.

## Features

Locomotion (smooth, strafe, snap/smooth turn, teleport, jump, physical jump,
crouch, sprint, jog, climb, flight, glide, grapple, wall walk, world grab,
wind, footsteps) · comfort (vignette, head-in-wall fade, height calibration,
seated mode, loading prompt) · hands (low-poly hands, collision hands, pickup,
ranged pickup, two-hand grab, laser pointer, gaze pointer, poke, pockets,
wrist menu, hand-pose areas, haptics, virtual keyboard, interactables) ·
system (controller-free hand tracking, Quest passthrough, desktop fallback,
debug HUD, refresh/physics rate) · persistence (save/load, items carried
between zones) · start menu with XR Tools user settings.

Full list with toggle names and defaults: **[docs/FEATURES.md](docs/FEATURES.md)**.
See them all in the **Showcase** zone: start menu → *New Game* → *Showcase*.

## One config file

```
config/vr_features_default.tres      # VRFeatureConfig: 44 switches, grouped like the feature list
project.godot → vr_template/feature_config = "res://config/vr_features_default.tres"
```

Copy the `.tres`, point the project setting at the copy, tick what your game
needs. Features can also be switched at runtime:

```gdscript
VRFeatures.set_enabled(&"teleport", false)
if VRFeatures.is_enabled(&"haptics"): Haptics.tap(controller)
```

How it works and how to add your own toggle: [docs/HOWTO_TOGGLE.md](docs/HOWTO_TOGGLE.md).

## Quick start

### 1. Requirements

- Godot **4.6** editor + the 4.6 export templates (*Editor → Manage Export
  Templates*).
- For Quest exports: **JDK 17**, **Android SDK** (platform 34, build-tools
  34, NDK, cmake) with `ANDROID_HOME` set, `adb`, developer mode on the Quest.

### 2. Setup

```bash
git clone https://github.com/eedali/Godot-VR-Template.git
cd Godot-VR-Template
bash tools/setup_vendors.sh
```

`setup_vendors.sh` downloads OpenXR Vendors 4.3.0-stable into
`addons/godotopenxrvendors/` (gitignored; the version must match
`OPENXR_VENDORS_VERSION` in `.github/workflows/publish-demo-on-push.yaml`).
Without Git Bash: download
`https://github.com/GodotVR/godot_openxr_vendors/releases/download/4.3.0-stable/godotopenxrvendorsaddon.zip`
and copy its `asset/addons/godotopenxrvendors` folder into `addons/`.

Open the project in Godot 4.6. For Quest builds install the Android build
template once: *Project → Install Android Build Template...* (or
`godot --headless --path . --install-android-build-template --quit`).

### 3. PC

Press Play with a PC VR runtime running (SteamVR, Quest Link, ...). Without a
headset Godot shows "OpenXR was requested but failed to start" and the game
continues in desktop mode: WASD / arrows to move, mouse to look, Space jump,
C / Ctrl crouch, Shift sprint, left click on UI, Esc releases the mouse.

```bash
bash tools/godot.sh --headless --path . --export-debug "Windows" build/windows/Game.exe
```

The Windows build is a plain OpenXR app, so it works with SteamVR; there is
no Steamworks integration.

### 4. Quest 3

```bash
bash tools/godot.sh --headless --path . --export-debug "Android Quest"
adb install -r build/android-quest/Game.apk
adb logcat -s godot
```

Splash → start menu → New Game (Easy / Normal / Hard start in *Outside*, or
*Showcase*). The demo zones are `outside`, `house_interior`,
`house_back_yard` and `showcase`.

## Making a new game

Checklist (identity, package name, icon, zones, starting zone, signing,
per-platform render settings): **[docs/HOWTO_NEW_GAME.md](docs/HOWTO_NEW_GAME.md)**.

## Folder layout

```
config/                 VRFeatureConfig script + the default feature config
components/
  player/               PlayerRig: XROrigin3D, camera, hands, every mechanic
  system/               VRFeatures autoload, passthrough, desktop fallback, debug HUD,
                        FeatureGate / FeatureToggleButton / FeatureStatusLabel helpers
  feedback/             Haptics helper + tap preset
  interactables/        button, lever, slider, joystick, snap zone, hand-pose area, keyboard
  locomotion/           teleport pad, climbable wall, grapple target, wall-walk surface,
                        world-grab area, wind area
  persistent/           save/load system (world, zones, items, pockets, staging)
  helpers/              zone switch area, save point, scatter
game/
  main.tscn             staging (loading screen, StartXR); applies refresh/physics rate
  game_state.tscn       GameState autoload (new game, save, load, difficulty)
  start_scene/          start menu (New Game, Load, Options = XR Tools settings UI)
  zones/                zone_base.tscn + outside, house_interior, house_back_yard, showcase
  items/, objects/      demo pick-ups and storage
addons/godot-xr-tools/  XR Tools 4.5.2 (upstream, unmodified)
addons/godotopenxrvendors/  downloaded by tools/setup_vendors.sh / CI (gitignored)
tools/                  check.sh, smoke_test.gd, zone_load_test.gd, godot.sh, setup scripts
docs/                   FEATURES, HOWTO_TOGGLE, HOWTO_NEW_GAME, CHANGELOG
export_presets.cfg      Windows, Linux, Android Quest, WebXR
build/                  export outputs (gitignored)
```

## Checks

```bash
bash tools/check.sh            # import, smoke test (every script/scene/resource), gdlint
bash tools/check.sh --run      # + headless run + game-flow test: start menu -> new game ->
                               #   every zone, with default / all-on / minimal feature configs
bash tools/check.sh --export   # + Windows debug export
```

Logs go to `build/claude-logs/`. Expected noise: OpenXR init failures (no
headset), `Viewport Texture must be set` (XR Tools viewports instanced
outside the tree).

## CI (GitHub Actions)

- **Publish Demo** builds Windows, Linux, Android Quest (debug) and WebXR on
  every push and uploads the builds as artifacts. The export step fails on
  export errors or a missing output file. The Android job creates a
  throw-away debug keystore.
- **gdlint on push** lints `components config game tools` (rules in `.gdlintrc`).
- Tag pushes also zip the builds into a GitHub release and, if the
  `BUTLER_API_KEY` secret exists, push them to itch.io at `BUTLER_USER_GAME`
  (a placeholder — set your own page first).

## Release to-do (per game)

- Identity: name, icon, splash, `package/unique_name` (placeholder
  `com.vrstudio.xrgame`), version code — see HOWTO_NEW_GAME.
- **Meta Store:** release keystore (never commit it), AAB export,
  Meta developer account + app, VRC checks, store art, keep `targetSdk`
  current.
- **Steam:** Steamworks app; add a Steam plugin if you need achievements /
  overlay (not part of the template); test a Windows release export with SteamVR.
  Optionally move the PC renderer to Forward+ in a separate branch — Quest must
  stay on `gl_compatibility`.
- **Performance:** measure on Quest 3 at 72 / 90 / 120 Hz with hand tracking
  and passthrough; keep mobile textures compressed (ETC2/ASTC is on); respect
  the light/shadow budget in HOWTO_NEW_GAME §6.

## Known notes

- A headless Android export sometimes keeps running after the APK is written
  (gradle daemon). If `build/android-quest/Game.apk` exists, the export worked.
- `main` follows upstream (`GodotVR/godot-xr-template`); this template's work
  happens on branches of `eedali/Godot-VR-Template`.

## Credits and license

- Based on the [Godot XR Template](https://github.com/GodotVR/godot-xr-template)
  (MIT, see `LICENSE`). Godot XR Tools and OpenXR Vendors keep their own
  licenses.
- Version history: [VERSIONS.md](VERSIONS.md) (upstream template) and
  [docs/CHANGELOG.md](docs/CHANGELOG.md) (this template).
