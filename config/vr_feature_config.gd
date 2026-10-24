@tool
class_name VRFeatureConfig
extends Resource


## VR Feature Configuration
##
## One switch per VR mechanic of the template. The active configuration is
## loaded by the [code]VRFeatures[/code] autoload (from the project setting
## [code]vr_template/feature_config[/code]) and applied to every [PlayerRig].
##
## Copy [code]res://config/vr_features_default.tres[/code], edit the copy in
## the inspector and point the project setting at it to configure a game.
## Groups follow docs/claude/FEATURES.md. See docs/HOWTO_TOGGLE.md.


# Setting names, collected once from the script's exported properties
static var _feature_names : Array[StringName] = []


@export_group("Locomotion")

## Smooth (direct) movement with the thumbsticks
@export var direct_movement : bool = true

## Strafe (sideways movement) on the left thumbstick
@export var strafe : bool = true

## Turning with the right thumbstick
@export var turn : bool = true

## Turn mode (DEFAULT follows the user settings, see Options menu)
@export var turn_mode : XRToolsMovementTurn.TurnMode = XRToolsMovementTurn.TurnMode.DEFAULT

## Arc teleport on the left trigger
@export var teleport : bool = true

## Jump with the A/X button
@export var jump : bool = true

## Jump by physically jumping (or swinging the arms)
@export var physical_jump : bool = false

## Crouch with the B/Y button
@export var crouch : bool = true

## Sprint by clicking the left thumbstick
@export var sprint : bool = true

## Jog in place (arm swing) to move
@export var jog : bool = false

## Climb objects with an XRToolsClimbable
@export var climb : bool = false

## Flight (B/Y on the left controller)
@export var flight : bool = false

## Glide by spreading the arms while falling
@export var glide : bool = false

## Grapple hook on the right trigger (targets on layer 5)
@export var grapple : bool = false

## Walk on walls (surfaces on layer 4)
@export var wall_walk : bool = false

## Grab the world to move (needs world-grab areas in the zone)
@export var world_grab : bool = false

## Wind areas push the player
@export var wind : bool = false

## Footstep sounds (needs surface audio in the zone)
@export var footsteps : bool = false


@export_group("Comfort")

## Tunnelling vignette while moving/turning
@export var vignette : bool = true

## Let the vignette adjust its strength automatically
@export var vignette_auto_adjust : bool = true

## What happens when the head enters a wall
@export_enum("Push away", "Fade", "Disabled") var head_behavior : int = 1

## Calibrate the player height from the headset
@export var height_calibration : bool = true

## Player body (off = seated / arcade experiences without a physical body)
@export var player_body : bool = true

## Show the "hold to continue" prompt on every scene load (off = first load only)
@export var loading_prompt : bool = false


@export_group("Hands & Interaction")

## Show the low-poly hand models
@export var hand_models : bool = true

## Physical (collision) hands that cannot pass through walls
@export var collision_hands : bool = true

## Pick up objects with the grip
@export var pickup : bool = true

## Pick up objects from a distance
@export var ranged_pickup : bool = true

## Laser pointer for UI and pointable objects
@export var pointer : bool = true

## Show the pointer laser (off = invisible pointer)
@export var laser_visible : bool = true

## Gaze (head) pointer
@export var gaze_pointer : bool = false

## Poke with the index finger tip
@export var poke : bool = true

## Body pockets and back pocket
@export var pockets : bool = true

## Wrist menu on the left hand
@export var wrist_ui : bool = true

## Hand pose detection for hand-pose areas in the zone
@export var hand_pose_areas : bool = false

## Controller haptics (rumble)
@export var haptics : bool = true

## Virtual keyboard objects in zones
@export var virtual_keyboard : bool = false


@export_group("System")

## Show hand models for controller-free hand tracking (also needs the project
## setting xr/openxr/extensions/hand_tracking)
@export var hand_tracking : bool = true

## Mixed reality passthrough (Quest)
@export var passthrough : bool = false

## Keyboard/mouse controls when no headset is available
@export var desktop_fallback : bool = true

## Debug HUD with FPS, frame time, draw calls and memory (debug builds only)
@export var debug_hud : bool = false

## Target display refresh rate in Hz (0 = runtime default; Quest 3: 72/90/120)
@export var target_refresh_rate : int = 0

## Physics ticks per display frame
@export_range(1, 4) var physics_rate_multiplier : int = 1


@export_group("Behaviour")

## If true, nodes of disabled features are freed at startup (zero cost, no
## runtime re-enable). If false they stay in the tree disabled and can be
## toggled at runtime.
@export var remove_disabled_nodes : bool = false


## Returns true if the feature [param feature] is switched on. Non-boolean
## settings are converted (0 = off). Unknown names return false.
func is_enabled(feature : StringName) -> bool:
	if not has_feature(feature):
		return false
	return bool(get(feature))


## Returns true if [param feature] is a setting of this configuration (built-in
## Resource properties such as [code]resource_name[/code] are not settings)
func has_feature(feature : StringName) -> bool:
	return get_feature_names().has(feature)


## Returns the names of every setting in this configuration, in inspector order
func get_feature_names() -> Array[StringName]:
	if _feature_names.is_empty():
		for prop in get_property_list():
			var usage : int = prop["usage"]
			if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_STORAGE:
				_feature_names.append(StringName(prop["name"]))
	return _feature_names
