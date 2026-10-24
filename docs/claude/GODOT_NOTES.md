# Godot 4.6 + XR Tools 4.5.2 — notes for autonomous edits

Things that are easy to get wrong when editing this project without the editor
open. Read before Phase 1.

## 1. Headless CLI you will use

| Purpose | Command |
|---|---|
| Import / refresh class cache & uids | `godot --headless --path . --import` |
| Parse one script | `godot --headless --path . --check-only --script res://x.gd` — **unreliable here**: autoload names (`GameState`, `XRToolsUserSettings`) are not resolved in this mode; use the smoke test instead |
| Run a SceneTree script | `godot --headless --path . --script res://tools/x.gd` (script must `extends SceneTree` or `MainLoop`) |
| Run main scene N frames | `godot --headless --xr-mode off --path . --quit-after 240` |
| Run a specific scene | `godot --headless --xr-mode off --path . --quit-after 60 res://game/zones/outside/outside_zone.tscn` |
| Export | `godot --headless --path . --export-debug "Windows" build/windows/Game.exe` |
| Android template install (once) | `godot --headless --path . --install-android-build-template --quit` |

Anything that *runs* the project (`--script`, `--quit-after`, a scene path)
needs `--xr-mode off`: otherwise OpenXR init fails without a headset and Godot
shows a blocking modal alert on the desktop even in `--headless` mode.

Always go through `bash tools/godot.sh` — it picks the **console** build so output
reaches the terminal (the GUI exe prints nothing on Windows).

## 2. `.uid` files (Godot 4.4+)

Every script (and shader) gets a sibling `name.gd.uid` on import containing
`uid://...`. These must be **committed**; otherwise each machine generates a
different uid and references drift. After creating scripts: import → `git add`
the new `.uid` files. Never hand-write a uid; let the import create it.

## 3. Hand-written `.tscn` / `.tres`

- Header: `[gd_scene load_steps=N format=3]` — `load_steps` = number of
  `ext_resource` + `sub_resource` entries + 1; Godot tolerates a wrong value
  but keep it right. A `uid="uid://..."` on the header is **optional for new
  files**; the editor assigns one on first save. For references you write,
  `[ext_resource type="PackedScene" path="res://..." id="1_abc"]` without `uid`
  is valid.
- Node lines: `[node name="X" type="Node3D" parent="."]`,
  instancing: `[node name="X" parent="." instance=ExtResource("1_abc")]`,
  overriding a property of an instanced child: `[node name="Child" parent="X" index="0"]` then properties.
- `[editable path="X"]` at the end marks "Editable Children"; needed when you
  override nodes *inside* an instanced scene (e.g. `BoneAttachment3D` inside a
  hand). Copy the existing lines from `zone_base.tscn`.
- Inherited scenes (`[node name="Root" instance=ExtResource(base)]` as the
  **first** node with no `type`) cannot remove or replace inherited nodes; see
  `ARCHITECTURE.md §4`.
- Typed arrays in `.tres`: `Array[Resource("res://path.gd")]([ExtResource("..")])`
  (see `zone_database.tres`).
- Physics layers used by XR Tools (from `project.godot`): 1 static world,
  2 dynamic, 3 pickable, 4 wall walking, 5 grapple target, 17 held,
  18 player hands, 19 grab handles, 20 player body, 21 pointable, 22 hand pose
  areas, 23 UI objects. Masks are bitfields: layer n → `1 << (n-1)`.

## 4. Re-saving scenes to pick up uids (optional, Phase 1.5)

```gdscript
# tools/resave_scenes.gd  — run: godot --headless --path . --script res://tools/resave_scenes.gd
extends SceneTree
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	for path in _list("res://game") + _list("res://components"):
		var res := load(path)
		if res is PackedScene or res is Resource:
			var err := ResourceSaver.save(res, path)
			if err != OK: printerr("resave failed: ", path, " ", err)
	quit(0)
# _list(): recursive DirAccess scan for .tscn/.tres (copy from smoke_test.gd)
```

After running, **inspect `git diff --stat` and a few files**. Accept only if
the diff is uid additions / trivial reordering. If it rewrites large blocks or
drops `[editable ...]` lines, `git checkout -- game components` and mark the
task `[~]`.

## 5. XR Tools placement rules

- `XRToolsMovementProvider` subclasses (`movement_*.gd`) find the
  `XRToolsPlayerBody` via ancestors of their `XROrigin3D`; most are placed
  under a hand (`XRController3D` or the collision hand `AnimatableBody3D`) or
  under the origin. Each has an `order` (lower runs first). Upstream defaults
  (verified in 4.5.2): turn 5, direct 10, crouch 10, jog 10, sprint 11,
  climb 15, world-grab 15, jump 20, physical-jump 20, grapple 20, wall-walk 25,
  wind 25, flight 30, glide 35, footstep 1001. Keep the defaults; two providers
  with the same order on the same body are fine as long as they do different
  things (upstream ships direct+crouch both at 10).
- `XRToolsFunctionTeleport` is **not** a movement provider (it extends
  `XRToolsHandPalmOffset` and moves the body directly); it, `FunctionPointer`
  (`XRToolsHandAimOffset`), `FunctionPickup` and `FunctionPoseDetector` need an
  `XRController3D` ancestor (`XRHelpers.get_xr_controller(self)`).
  `FunctionGazePointer` must be a **direct child of `XRCamera3D`**.
- `XRToolsCollisionHand` (`hands/collision_hand.gd`): an `AnimatableBody3D`
  directly under the controller; the hand mesh scene and the functions go
  **under it**, exactly as `zone_base.tscn` does today.
- `XRToolsSceneBase` expects `$XROrigin3D/XRCamera3D`; `PersistentZone` expects
  `$XROrigin3D`. Node names matter.
- `XRToolsVignette` (`effects/vignette.tscn`) is a child of the camera; it uses
  render layer 2 (`layers = 2`) — keep the camera's cull mask default.
- Autoloads already present: `XRToolsUserSettings`, `XRToolsRumbleManager`
  (uid paths), `GameState`. Add `VRFeatures` **above** `GameState`.
- `XRToolsStaging` emits `xr_started` / `xr_ended`; `StartXR` emits
  `xr_failed_to_initialize` — the rig can listen through
  `PersistentStaging.instance.get_node("StartXR")`.

## 6. OpenXR in headless / desktop

- Headless: `XRServer.primary_interface` is `null`; every XR Tools node must
  tolerate that (they do). Your custom code must too.
- Desktop without HMD: XR Tools `desktop-support` nodes give WASD/mouse.
- Project keys you will touch:
  - `xr/openxr/extensions/hand_tracking` (bool, default **false** since 4.3)
  - `xr/openxr/extensions/hand_interaction_profile` (bool)
  - `xr/openxr/environment_blend_mode` (int: 0 opaque, 1 additive, 2 alpha)
  - `rendering/viewport/transparent_background` (bool) — passthrough needs the
    viewport transparent; set at runtime via `get_viewport().transparent_bg`.
  - Feature-tag overrides: `rendering/anti_aliasing/quality/msaa_3d.mobile=1`
    (the `.mobile` suffix applies on Android).
- Runtime passthrough API: `XRInterface.environment_blend_mode`,
  `XRInterface.get_supported_environment_blend_modes()`,
  `XRInterface.start_passthrough()` / `stop_passthrough()` (Meta needs the
  vendors plugin; on PC these return false — handle gracefully).

## 7. gl_compatibility limits (Quest)

No SDFGI, no volumetric fog, no SSR/SSAO; `Viewport2DIn3D` textures cost fill
rate — keep `throttle_fps` ≤ 15 and `update_mode` "throttled"/"on demand" as the
existing wrist UI does. Prefer `Label3D` for showcase titles over viewports.
Shadows: directional shadow on mobile is fine at 2048 atlas; avoid > 2 shadow
casters per zone.

## 8. Git on Windows

`.gitattributes` forces LF. Write files with LF. `git diff` noise of whole-file
CRLF changes means an editor saved CRLF — fix with `git add --renormalize .`.
`GIT_TERMINAL_PROMPT=0` makes git fail instead of hanging on a credential
prompt; the GCM GUI/browser window still appears once.

## 9. Things that look like bugs but are not

- `XRToolsFunctionPickup._pick_up_object.call_deferred(...)` in
  `persistent_zone.gd` calls a "private" method on purpose (upstream pattern).
- `prompt_for_continue = false` in `GameStaging._on_scene_loaded` is intentional
  (only the first load prompts).
- `save_file_password == ""` warning on every save is intentional until a game
  sets one.
