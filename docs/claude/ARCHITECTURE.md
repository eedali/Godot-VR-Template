# Target architecture

The template must let the owner start a new VR game by (1) editing one config
resource, (2) dropping a `PlayerRig` into a zone, (3) deleting what they do not
need. Nothing else should require touching XR Tools internals.

```
res://
  config/
    vr_feature_config.gd          # class_name VRFeatureConfig (Resource)
    vr_features_default.tres      # the shipped defaults (edit per game)
  components/
    player/
      player_rig.tscn / .gd       # XROrigin3D + camera + hands + every mechanic
      player_rig_hand.tscn        # one hand (left/right via export), inner structure
    system/
      vr_features.gd              # autoload "VRFeatures": loads config, applies, signals
      passthrough_controller.gd   # Quest MR passthrough on/off at runtime
      desktop_fallback.tscn       # WASD/mouse rig pieces when no HMD
      debug_hud.tscn / .gd        # fps / frametime / battery label
    feedback/
      haptics.gd                  # class_name Haptics – thin wrapper over XRToolsRumbleManager
    interactables/                # prefab scenes: button, area_button, handle, hinge, slider, joystick, snap_zone, climbable
    locomotion/                   # prefab zone-side pieces: teleport_area, world_grab_area, wind_area
    persistent/                   # (existing) persistence system
    helpers/                      # (existing) scatter, zone_switch_area, zone_save_point
  game/
    main.tscn, game_state.tscn    # (existing) staging + state
    start_scene/                  # (existing) menu; Options pane gets XRToolsUserSettingsUI
    zones/
      zone_base.tscn              # instances components/player/player_rig.tscn
      showcase/showcase_zone.tscn # every mechanic as a labelled station
      outside/, house_interior/, house_back_yard/   # (existing demo zones, now thin)
  docs/
    FEATURES.md, HOWTO_NEW_GAME.md, HOWTO_TOGGLE.md, CHANGELOG.md
```

## 1. `VRFeatureConfig` (Resource)

```gdscript
@tool
class_name VRFeatureConfig
extends Resource

## One switch per mechanic. Grouped so the inspector reads like FEATURES.md.

@export_group("Locomotion")
@export var direct_movement := true
@export var strafe := true
@export var turn := true
@export var turn_mode : XRToolsMovementTurn.TurnMode = XRToolsMovementTurn.TurnMode.DEFAULT
@export var teleport := true
@export var jump := true
@export var physical_jump := false
@export var crouch := true
@export var sprint := true
@export var jog := false
@export var climb := false
@export var flight := false
@export var glide := false
@export var grapple := false
@export var wall_walk := false
@export var world_grab := false
@export var wind := false
@export var footsteps := false

@export_group("Comfort")
@export var vignette := true
@export var vignette_auto_adjust := true
@export_enum("Push away", "Fade", "Disabled") var head_behavior := 1
@export var height_calibration := true
@export var player_body := true
@export var loading_prompt := false

@export_group("Hands & Interaction")
@export var hand_models := true
@export var collision_hands := true
@export var pickup := true
@export var ranged_pickup := true
@export var pointer := true
@export var laser_visible := true
@export var gaze_pointer := false
@export var poke := true
@export var pockets := true
@export var wrist_ui := true
@export var hand_pose_areas := false
@export var haptics := true
@export var virtual_keyboard := false

@export_group("System")
@export var hand_tracking := true
@export var passthrough := false
@export var desktop_fallback := true
@export var debug_hud := false
@export var target_refresh_rate := 0        # 0 = runtime default; Quest 3: 72/90/120
@export var physics_rate_multiplier := 1

@export_group("Behaviour")
## true  = nodes of disabled features are freed at startup (zero cost, no runtime re-enable)
## false = nodes stay in the tree with `enabled = false` (can be toggled at runtime)
@export var remove_disabled_nodes := false
```

Rules:
- Every property is a plain `@export`; **no logic in the resource** except an
  optional `is_enabled(name : StringName) -> bool` that uses `get(name)`.
- Keep defaults equal to what the demo zones ship with today, plus teleport and
  vignette on. "Exotic" locomotion defaults off.
- The default resource file lives at `res://config/vr_features_default.tres`.
  A game may point `VRFeatures.config_path` (project setting
  `vr_template/feature_config`, see below) at its own copy.

## 2. `VRFeatures` autoload (`components/system/vr_features.gd`)

```gdscript
extends Node
## Autoload "VRFeatures". Holds the active VRFeatureConfig and broadcasts changes.

signal feature_changed(name : StringName, enabled : bool)
signal config_replaced(config : VRFeatureConfig)

const SETTING_PATH := "vr_template/feature_config"     # ProjectSettings key, string path to .tres
const DEFAULT_PATH := "res://config/vr_features_default.tres"

var config : VRFeatureConfig

func _ready() -> void:
	var path : String = ProjectSettings.get_setting(SETTING_PATH, DEFAULT_PATH)
	var loaded := load(path) as VRFeatureConfig
	config = loaded.duplicate(true) if loaded else VRFeatureConfig.new()   # never mutate the .tres at runtime

func is_enabled(name : StringName) -> bool:
	return bool(config.get(name))

func set_enabled(name : StringName, value : bool) -> void:
	if config.get(name) == null: push_warning(...); return
	if bool(config.get(name)) == value: return
	config.set(name, value)
	feature_changed.emit(name, value)
```

- Register the ProjectSettings key with `ProjectSettings.set_setting` +
  `set_initial_value` in an editor plugin **only if** cheap; otherwise document
  the key and read it with a default. (Decision: start with "read with default";
  no editor plugin.)
- Add `VRFeatures="*res://components/system/vr_features.gd"` to `[autoload]`
  in `project.godot`, **before** `GameState`.

## 3. `PlayerRig` (`components/player/player_rig.tscn`)

One scene, instanced by `zone_base.tscn` under `PersistentZone`:

```
PlayerRig (XROrigin3D, script player_rig.gd)
├── XRCamera3D
│   ├── Vignette                (effects/vignette.tscn)           [vignette]
│   ├── FunctionGazePointer     (functions/function_gaze_pointer) [gaze_pointer]
│   ├── DebugHUD                (components/system/debug_hud)     [debug_hud]
│   └── BackPocket              (persistent_pocket)               [pockets]
├── LeftHand  (XRController3D, tracker left_hand, pose grip)
│   └── CollisionHandLeft (AnimatableBody3D, collision_hand.gd)   [collision_hands → when off, children re-parent directly under LeftHand]
│       ├── LeftHandModel (hands/scenes/lowpoly/left_hand_low)    [hand_models]
│       │   └── … Skeleton3D/BoneAttachment3D/Poke                [poke]
│       ├── FunctionPointer                                       [pointer, laser_visible]
│       ├── FunctionPickup                                        [pickup, ranged_pickup]
│       ├── FunctionTeleport                                      [teleport]
│       ├── MovementDirect (strafe)                               [direct_movement, strafe]
│       ├── MovementJump                                          [jump]
│       ├── MovementCrouch                                        [crouch]
│       ├── MovementFlight                                        [flight]
│       ├── FunctionPoseDetector                                  [hand_pose_areas]
│       └── WristUI (viewport_2d_in_3d → zone_wrist_ui)          [wrist_ui]
├── RightHand (XRController3D, tracker right_hand, pose grip)
│   └── CollisionHandRight
│       ├── RightHandModel … Poke                                 [hand_models, poke]
│       ├── FunctionPointer                                       [pointer]
│       ├── FunctionPickup                                        [pickup]
│       ├── MovementDirect                                        [direct_movement]
│       ├── MovementTurn                                          [turn, turn_mode]
│       ├── MovementJump / MovementCrouch                         [jump, crouch]
│       ├── MovementGrapple                                       [grapple]
│       └── FunctionPoseDetector                                  [hand_pose_areas]
├── PlayerBody (player/player_body.tscn)                          [player_body, height_calibration, head_behavior]
│   ├── LeftPocket / RightPocket (+ HighlightRing)                [pockets]
├── MovementSprint                                                [sprint]
├── MovementClimb                                                 [climb]
├── MovementGlide                                                 [glide]
├── MovementWallWalk                                              [wall_walk]
├── MovementWorldGrab                                             [world_grab]
├── MovementJog                                                   [jog]
├── MovementPhysicalJump                                          [physical_jump]
├── MovementFootstep                                              [footsteps]
├── MovementWind                                                  [wind]
├── PassthroughController                                         [passthrough]
└── DesktopFallback (instanced at runtime only when no XR interface) [desktop_fallback]
```

`player_rig.gd`:

```gdscript
@tool
class_name PlayerRig
extends XROrigin3D

## Maps VRFeatureConfig property names to node paths inside this scene.
## One feature may drive several nodes (left + right).
const FEATURE_NODES : Dictionary = {
	&"teleport": ["LeftHand/CollisionHandLeft/FunctionTeleport"],
	&"direct_movement": ["LeftHand/CollisionHandLeft/MovementDirect", "RightHand/CollisionHandRight/MovementDirect"],
	# ... every toggle in FEATURES.md
}

func _ready() -> void:
	if Engine.is_editor_hint(): return
	_apply_all(VRFeatures.config)
	VRFeatures.feature_changed.connect(_on_feature_changed)
```

- `_apply_all` iterates `FEATURE_NODES`; for each node: if it has an `enabled`
  property → set it; else `process_mode` + `visible` (for `Node3D`) + for
  `XRToolsViewport2DIn3D` use its `enabled`. If `config.remove_disabled_nodes`
  → `queue_free()` instead.
- Special cases handled in dedicated small methods: `collision_hands`
  (re-parent the hand subtree so functions still hang under the controller),
  `turn_mode`, `ranged_pickup` (`ranged_distance = 0` when off), `laser_visible`
  (`show_laser`), `head_behavior`, `hand_tracking` (`show_when_tracked`),
  `target_refresh_rate` / `physics_rate_multiplier` (applied to the staging
  `StartXR` through `XRToolsStaging.instance`? — no: `PersistentStaging.instance.get_node("StartXR")`),
  `desktop_fallback` (instance scene when `XRServer.primary_interface == null`
  after staging reports `xr_failed_to_initialize`; otherwise skip).
- The rig exposes `get_feature_node(name) -> Node` for game code.
- **Every path in `FEATURE_NODES` is validated once in `_ready` with
  `has_node`; a missing path is a `push_error`, not a silent skip, and
  `tools/smoke_test.gd` must be extended in Phase 3 to instantiate the rig and
  assert all paths exist** (instantiate → `for p in FEATURE_NODES.values()` →
  `has_node`).

## 4. Zones after the refactor

**Inheritance constraint.** Today `zone_base.tscn` inherits
`components/persistent/persistent_zone.tscn`, which inherits XR Tools'
`staging/scene_base.tscn`; that base scene *owns* the `XROrigin3D`, `XRCamera3D`,
`LeftHand`, `RightHand` nodes. An inherited scene cannot replace an inherited
node with an instance of another scene. Therefore `zone_base.tscn` must **stop
inheriting** and become a plain scene:

```
ZoneBase (Node3D, script = components/persistent/persistent_zone.gd)
└── XROrigin3D   ← [node name="XROrigin3D" instance=ExtResource(player_rig.tscn)]
```

- The instanced rig **must be named `XROrigin3D`** and its camera **`XRCamera3D`**,
  hands **`LeftHand`/`RightHand`**, because `scene_base.gd` uses
  `$XROrigin3D/XRCamera3D`, `persistent_zone.gd` uses `$XROrigin3D`, and
  `XRToolsFunctionPickup.find_left($XROrigin3D)` searches below it.
- `components/persistent/persistent_zone.tscn` stays in the repo (other
  projects may inherit it) but `zone_base.tscn` no longer uses it.
- The three demo zones inherit `zone_base.tscn`; rewrite them so they keep
  **only their `World`/content nodes** and drop every copied rig override
  (`XROrigin3D/LeftHand/...` blocks, blend trees, bone rotations). Their
  `zone_info`, spawn `Marker3D`s and `ZoneSwitchArea`s stay.
- Controller pose: today the hands use `pose = &"grip"`; keep that on the rig.

## 5. Custom components (new code)

- `components/system/passthrough_controller.gd` (`Node`, exported `enabled`):
  on enable — `var xr := XRServer.find_interface("OpenXR")`; if it supports
  `XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND` (`get_supported_environment_blend_modes()`),
  set `xr.environment_blend_mode`, `get_viewport().transparent_bg = true`, and
  swap the zone's `WorldEnvironment.environment.background_mode` to
  `Environment.BG_CLEAR_COLOR`/transparent. On disable — restore the previous
  values. Also calls `xr.start_passthrough()` / `stop_passthrough()` where the
  vendor plugin needs it. Emits `passthrough_changed(bool)`.
- `components/feedback/haptics.gd` (`class_name Haptics`, static helpers):
  `pulse(controller : XRController3D, magnitude : float, duration_ms : int, key := &"pulse")`
  builds an `XRToolsRumbleEvent` (`magnitude`, `duration_ms`) and calls the
  existing autoload `XRToolsRumbleManager.add(key, event, [controller])`
  (signature: `add(event_key : Variant, event : XRToolsRumbleEvent, trackers : Array)`;
  a controller node is accepted and mapped to its tracker). Respects
  `VRFeatures.is_enabled(&"haptics")` and `XRToolsUserSettings.haptics_scale`.
  Ship one `tap.tres` preset (XR Tools has `rumble/tap_rumble.tres` to copy).
- `components/system/debug_hud.tscn`: `XRToolsViewport2DIn3D` + Label updated at
  4 Hz (`throttle_fps`); shows FPS, frame time, draw calls
  (`RenderingServer.get_rendering_info`), battery
  (`OS.get_power_percent_left`).
- `components/system/desktop_fallback.tscn`: the XR Tools `desktop-support`
  nodes (`mouse_capture`, `movement_desktop_*`, `function_desktop_pointer`,
  `controller_hider`) grouped so the rig can instance them in one call.

## 6. Showcase zone (`game/zones/showcase/showcase_zone.tscn`)

A flat 30 m × 30 m prototype-material arena. Stations (each a `Node3D` with a
3D label built from `Label3D`):

1. Locomotion field (teleport areas, a climbable wall, grapple targets on
   layer 5, a wall-walk ramp on layer 4, a world-grab area, a wind corridor).
2. Interaction table (area button, hinge door, slider, joystick, handle, snap
   zone with return-to-snap item, pickable with two-hand grab).
3. UI station (viewport-in-3D menu, virtual keyboard, pointer target).
4. Comfort/settings kiosk (XRToolsUserSettingsUI on a panel, passthrough toggle
   button, debug HUD toggle).
5. Persistence corner (save point, pocket demo, zone switch back to Outside).

Register it in `zone_database.tres` and add a "Showcase" button in the start
menu (New Game pane) that starts there. The default `starting_zone` stays
`outside` to keep the original demo intact.
