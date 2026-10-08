# VRStudio XR Game — Godot VR Template (Quest 3 + Steam ready)

> Based on upstream [godotVR/godot-xr-template](https://github.com/godotVR/godot-xr-template)
> (`main` branch), prepared with **Meta Quest 3 first** and **Steam PCVR** targets.
> Ships with splash + start menu + 3 demo scenes, ready to run and test.

| Target | Status |
|---|---|
| Quest 3 (APK, debug) | ✅ Builds, on-device test pending on your side |
| PC Windows (SteamVR-compatible OpenXR) | ✅ Builds |
| Meta Store release (AAB, release signature) | ⬜ TODO (below) |
| Steam release | ⬜ TODO (below) |

Tested versions: **Godot 4.6 stable**, **XR Tools 4.5.1**,
**OpenXR Vendors 4.3.0-stable**, **JDK 17**, **Android SDK 34 / min 32**.

---

## 1. Requirements

- **Godot 4.6 stable** (editor). Install the 4.6 export templates via
  `Editor → Manage Export Templates`.
- **OpenXR Vendors 4.3.0-stable** — NOT in the repo (intentionally `.gitignore`d).
  CI and the setup step below download it. The version must match
  `OPENXR_VENDORS_VERSION` in `.github/workflows/publish-demo-on-push.yaml`.
- For Android export: **JDK 17** + **Android SDK** (platform 34, build-tools 34,
  NDK, cmake) + `ANDROID_HOME` set.
- For on-device Quest 3 testing: `adb` (SDK platform-tools) + developer mode on Quest.

## 2. Setup

```powershell
git clone https://github.com/eedali/Godot-VR-Template.git
```

1. Install the vendors plugin (run from the repo root):
   ```powershell
   # Download the 4.3.0-stable zip:
   # https://github.com/GodotVR/godot_openxr_vendors/releases/download/4.3.0-stable/godotopenxrvendorsaddon.zip
   # Copy the asset/addons/godotopenxrvendors folder into addons/
   ```
2. Open the project with Godot 4.6 → automatic import starts.
3. Install the Android build template (once):
   `Project → Install Android Build Template...`
   (or headless: `godot --headless --path . --install-android-build-template --quit`)
4. Check the **Android Quest** and **Windows** presets in `Project → Export`.

## 3. Quick test

### On PC (no headset)

The template includes `godot-xr-tools` **desktop-support**; without an HMD the game
starts in normal mode (WASD + mouse). The OpenXR error
(`Failed to create XR instance`) is **expected** in that case.

```powershell
# Windows debug build
godot --headless --path . --export-debug "Windows"
# output: build/windows/Game.exe
```

### On Quest 3

```powershell
adb devices
adb install -r build/android-quest/Game.apk
```

Open **VRStudio XR Game** on the headset: splash → start menu → 3 zones
(`house_interior`, `house_back_yard`, `outside`). Try teleport, crate/rock grab,
hand tracking and passthrough.

Logs: `adb logcat | Select-String "godot|openxr|vrstudio"`

## 4. Project settings (why this way?)

- `project.godot` → `rendering_method = gl_compatibility` (both desktop and mobile).
  **Required on Quest.** If you want better visuals for Steam later, you can switch
  the desktop side to `Forward+`, but Quest (`*.mobile`) must stay `gl_compatibility`.
- `xr/openxr`: `enabled=true`, foveation level 3 + dynamic (Quest performance),
  Meta starting color space.
- `export_presets.cfg` → **Android Quest**: `com.vrstudio.xrgame`, v1.0.0,
  `minSdk 32 / targetSdk 34`, single `arm64-v8a` architecture, Meta plugin enabled,
  Quest 2/3/Pro support on, Quest 1 off, hand tracking + passthrough on,
  eye tracking off (Quest 3 has no eye tracking).
- **Windows**: `VRStudio / VRStudio XR Game 1.0.0`, works with the SteamVR OpenXR
  runtime, no extra plugin needed.
- Note: the upstream `build/android-hronos` typo was fixed to `build/android-khronos`
  (for consistency with the CI artifact folder).

## 5. Folder structure

```
game/            # main.tscn, game_state (singleton), start_scene, zones, items
components/      # persistent staging/world/zone system
addons/godot-xr-tools/   # XR Tools 4.5.1 (in repo)
addons/godotopenxrvendors/ # downloaded by CI/setup, NOT in repo
export_presets.cfg  # Windows, Linux, Android Quest, WebXR
openxr_action_map.tres
build/           # export outputs (not in git, .gitignore)
android/         # build template (not in git, .gitignore)
```

## CI (GitHub Actions)

`Publish Demo` builds **Windows, Linux, Android Quest, WebXR** on every push
(Pico/Lynx/Khronos targets were dropped — Quest-only focus). Notes:

- Ubuntu runners already ship the Android SDK; the workflow installs the
  required packages directly (the old `setup-android` action step was removed —
  it called the long-gone `sdkmanager tools` package and failed all Android jobs).
- `fail-fast` is off, so one platform failing won't cancel the others.
- Release/tag-only steps (butler, zip, GitHub Release) need `BUTLER_API_KEY`
  only for itch.io; plain pushes just upload build artifacts.

## 6. TODO — remaining work

### Game identity (required)
- [ ] `icon.png` → replace with your own game icon (currently the Godot icon)
- [ ] `assets/splash/splash.png` → your own splash
- [ ] `project.godot` → `config/name` with the real game name
- [ ] `export_presets.cfg` → `package/unique_name` with your real publisher package
  (currently placeholder `com.vrstudio.xrgame`) and `package/name`
- [ ] Replace demo zones with your own scenes (`game/zones/`), pick the starting
  zone on `game_state.tscn`

### Meta Store release
- [ ] Generate a release keystore (a store release cannot use the debug keystore)
  and keep it safe
- [ ] Release build: `gradle_build/export_format` → AAB, `--export-release`
- [ ] Meta Quest Developer account + app registration, pass the VRC tests
- [ ] Icon, cover art, age/privacy declarations, keep `targetSdk` up to date

### Steam release
- [ ] Steamworks account + app registration; add a Godot Steam plugin if needed
  (not in the template — only OpenXR PCVR is ready)
- [ ] Take a Windows **release** export, test on a PC with SteamVR installed
- [ ] Optionally switch the PC side to `Forward+` + high-quality materials/lights
  (separate branch recommended, Quest stays `gl_compatibility`)

### Quality / performance
- [ ] Measure frame rate on Quest 3 at 72/90/120 Hz with hand tracking + passthrough on
- [ ] Texture compression: ETC2/ASTC for mobile (`textures/vram_compression` is on),
  downscale unnecessary 4K textures
- [ ] Reduce light/shadow count to the mobile budget, mind `gl_compatibility` limits

## 7. Known notes

- After a headless Android export the Godot process sometimes does not exit
  immediately (gradle daemon) — if the APK exists
  (`build/android-quest/Game.apk` ~97 MB) all is fine, you can kill the process.
- The OpenXR warning when running on a PC without an HMD is normal (desktop fallback).
- `main` follows upstream; the pulled commit is `654622d`
  (Godot 4.6.1 / XR Tools 4.5.1 upgrade). Upstream lives in the `upstream` remote,
  your own work goes to `origin` (`eedali/Godot-VR-Template`).

## 8. Credits / license

- Template: [Godot XR Template](https://github.com/GodotVR/godot-xr-template) — MIT
  (see `LICENSE`). XR Tools and OpenXR Vendors have their own licenses.
- This repo keeps the upstream MIT license. Clarify the license of your own
  game code/art content before releasing to stores.
