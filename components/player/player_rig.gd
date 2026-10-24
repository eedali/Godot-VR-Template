@tool
class_name PlayerRig
extends XROrigin3D


## Player Rig
##
## The complete VR player: XROrigin3D, camera, both hands (collision hands,
## hand models, poke, pointer, pickup, teleport, pose detectors), every
## movement provider, the player body with pockets, the wrist UI, comfort
## vignette, gaze pointer, debug HUD and passthrough controller. Zones
## instance this scene as their [code]XROrigin3D[/code] node (see
## components/persistent/persistent_zone.tscn).
##
## Which mechanics are active is decided by the [VRFeatureConfig] held by the
## [code]VRFeatures[/code] autoload. [constant FEATURE_NODES] maps each
## feature to the nodes it switches on/off; [constant SETTING_NODES] lists
## features that change a property of a node instead (each has a handler in
## [method _apply_setting]); [constant EXTERNAL_FEATURES] lists the features
## handled outside the rig. The rig follows runtime changes made through
## [code]VRFeatures.set_enabled()[/code] / [code]set_value()[/code].
##
## Rules between features:
## [br]- movement features need the player body; with [code]player_body[/code]
##   off they are forced off (a warning lists them), and so are the hip pockets.
## [br]- with [code]flight[/code] on, the left-hand crouch is off (both use B/Y).
## [br]- the left-hand teleport pauses while the left pointer is on a target
##   or the left hand holds something (all three use the left trigger).


## Emitted after the whole configuration has been applied
signal features_applied


## Bone attachments carrying the pokes (index finger tips)
const LEFT_TIP := "LeftHand/CollisionHandLeft/LeftHandModel/Hand_Nails_low_L/" \
		+ "Armature/Skeleton3D/BoneAttachment3D"
const RIGHT_TIP := "RightHand/CollisionHandRight/RightHandModel/Hand_Nails_low_R/" \
		+ "Armature/Skeleton3D/BoneAttachment3D"

## Features that switch nodes on/off. Every path is relative to the rig.
## Nodes with an [code]enabled[/code] property get it set; other nodes get
## [member Node.process_mode] set. [Node3D]s are also hidden.
const FEATURE_NODES : Dictionary = {
	# Locomotion
	&"direct_movement": [
		"LeftHand/CollisionHandLeft/MovementDirect",
		"RightHand/CollisionHandRight/MovementDirect",
	],
	&"turn": ["RightHand/CollisionHandRight/MovementTurn"],
	&"teleport": ["LeftHand/CollisionHandLeft/FunctionTeleport"],
	&"jump": [
		"LeftHand/CollisionHandLeft/MovementJump",
		"RightHand/CollisionHandRight/MovementJump",
	],
	&"physical_jump": ["MovementPhysicalJump"],
	&"crouch": [
		"LeftHand/CollisionHandLeft/MovementCrouch",
		"RightHand/CollisionHandRight/MovementCrouch",
	],
	&"sprint": ["MovementSprint"],
	&"jog": ["MovementJog"],
	&"climb": ["MovementClimb"],
	&"flight": ["MovementFlight"],
	&"glide": ["MovementGlide"],
	&"grapple": ["RightHand/CollisionHandRight/MovementGrapple"],
	&"wall_walk": ["MovementWallWalk"],
	&"world_grab": ["MovementWorldGrab"],
	&"wind": ["MovementWind"],
	&"footsteps": ["MovementFootstep"],
	# Comfort
	&"vignette": ["XRCamera3D/Vignette"],
	&"player_body": ["PlayerBody"],
	# Hands & interaction
	&"pickup": [
		"LeftHand/CollisionHandLeft/FunctionPickup",
		"RightHand/CollisionHandRight/FunctionPickup",
	],
	&"pointer": [
		"LeftHand/CollisionHandLeft/FunctionPointer",
		"RightHand/CollisionHandRight/FunctionPointer",
	],
	&"gaze_pointer": ["XRCamera3D/FunctionGazePointer"],
	&"poke": [
		LEFT_TIP + "/Poke",
		RIGHT_TIP + "/Poke",
	],
	&"pockets": [
		"XRCamera3D/BackPocket",
		"PlayerBody/LeftPocket",
		"PlayerBody/RightPocket",
	],
	&"wrist_ui": ["LeftHand/CollisionHandLeft/WristUI"],
	&"hand_pose_areas": [
		"LeftHand/CollisionHandLeft/FunctionPoseDetector",
		"RightHand/CollisionHandRight/FunctionPoseDetector",
	],
	# System
	&"passthrough": ["PassthroughController"],
	&"debug_hud": ["XRCamera3D/DebugHUD"],
}

## Features that modify properties of nodes (handled in [method _apply_setting])
const SETTING_NODES : Dictionary = {
	&"strafe": ["LeftHand/CollisionHandLeft/MovementDirect"],
	&"turn_mode": ["RightHand/CollisionHandRight/MovementTurn"],
	&"vignette_auto_adjust": ["XRCamera3D/Vignette"],
	&"head_behavior": ["PlayerBody"],
	&"height_calibration": ["PlayerBody"],
	&"hand_models": [
		"LeftHand/CollisionHandLeft/LeftHandModel",
		"RightHand/CollisionHandRight/RightHandModel",
	],
	&"collision_hands": [
		"LeftHand/CollisionHandLeft",
		"RightHand/CollisionHandRight",
	],
	&"ranged_pickup": [
		"LeftHand/CollisionHandLeft/FunctionPickup",
		"RightHand/CollisionHandRight/FunctionPickup",
	],
	&"laser_visible": [
		"LeftHand/CollisionHandLeft/FunctionPointer",
		"RightHand/CollisionHandRight/FunctionPointer",
	],
	&"hand_tracking": ["LeftHand", "RightHand"],
	&"desktop_fallback": ["."],
}

## Features handled outside the rig, and where
const EXTERNAL_FEATURES : Dictionary = {
	&"haptics": "Haptics helper (components/feedback/haptics.gd), used by the rig",
	&"virtual_keyboard": "FeatureGate on zone keyboards (components/interactables)",
	&"loading_prompt": "GameStaging (game/main.gd)",
	&"target_refresh_rate": "GameStaging -> StartXR (game/main.gd)",
	&"physics_rate_multiplier": "GameStaging -> StartXR (game/main.gd)",
	&"remove_disabled_nodes": "PlayerRig startup (_enter_tree)",
}

## Movement features driven by the player body (forced off without it).
## Keep in sync with DEPENDENTS[&"player_body"].
const BODY_FEATURES : Array[StringName] = [
	&"direct_movement", &"turn", &"jump", &"physical_jump", &"crouch", &"sprint",
	&"jog", &"climb", &"flight", &"glide", &"grapple", &"wall_walk", &"world_grab",
	&"wind", &"footsteps",
]

## Features whose state depends on another feature
const DEPENDENTS : Dictionary = {
	&"player_body": [
		&"direct_movement", &"turn", &"jump", &"physical_jump", &"crouch", &"sprint",
		&"jog", &"climb", &"flight", &"glide", &"grapple", &"wall_walk", &"world_grab",
		&"wind", &"footsteps", &"pockets",
	],
	&"flight": [&"crouch"],
}

## Features whose nodes are never freed by remove_disabled_nodes, because
## other systems hold references to them (GameState saves through the
## PlayerBody, persistence restores held and pocketed items)
const NEVER_FREE : Array[StringName] = [
	&"player_body",
	&"pickup",
	&"pockets",
]

## Interaction profile reported by controllers driven by optical hand tracking
const HAND_INTERACTION_PROFILE := "/interaction_profiles/ext/hand_interaction_ext"

## Keyboard/mouse controls added when no XR interface is available
const DESKTOP_FALLBACK_SCENE := "res://components/system/desktop_fallback.tscn"


## Vignette radius used when [code]vignette_auto_adjust[/code] is off
## (1.0 = invisible, smaller = stronger permanent tunnel)
@export_range(0.1, 1.0) var static_vignette_radius : float = 0.8


## Configuration currently applied to this rig
var config : VRFeatureConfig

# Scene values of properties the settings overwrite, keyed by node + property,
# so switching a setting back restores what the scene designer chose.
var _scene_values : Dictionary = {}

# Teleport guard state (left trigger is shared with pointer and pickup)
var _left_pointer_on_target : bool = false
var _left_hand_holding : bool = false

# Instanced desktop fallback (null while not needed)
var _desktop_fallback : Node

# True once the startup removal of disabled nodes has run
var _removed_disabled : bool = false

# True once the "player_body is off" warning was printed
var _warned_no_body : bool = false

# Left controller (shares its trigger between teleport, pointer and pickup)
@onready var _left_controller : XRController3D = get_node_or_null(^"LeftHand")


# Add support for is_xr_class on XRTools classes
func is_xr_class(p_name : String) -> bool:
	return p_name == "PlayerRig"


# Free nodes of disabled features before the children enter the tree, so they
# never register with the player body or any group.
func _enter_tree() -> void:
	if Engine.is_editor_hint() or _removed_disabled:
		return
	_removed_disabled = true
	config = _load_config()
	if config.remove_disabled_nodes:
		_remove_disabled_nodes()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_validate_paths()
	_connect_hand_signals()

	var features := _get_features()
	if features:
		config = features.config
		features.value_changed.connect(_on_feature_value_changed)
		features.config_replaced.connect(_on_config_replaced)

	_apply_all(true)


# Report missing feature nodes in the editor
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	for path in get_missing_paths():
		warnings.append("Feature node missing: %s" % path)
	return warnings


## Returns every node path referenced by [constant FEATURE_NODES] and
## [constant SETTING_NODES]
static func get_all_feature_paths() -> Array[String]:
	var paths : Array[String] = []
	for table : Dictionary in [FEATURE_NODES, SETTING_NODES]:
		for feature in table:
			for path : String in table[feature]:
				if not paths.has(path):
					paths.append(path)
	return paths


## Returns the feature node paths that do not exist below this rig
func get_missing_paths() -> Array[String]:
	var missing : Array[String] = []
	for path in get_all_feature_paths():
		if not has_node(path):
			missing.append(path)
	return missing


## Returns the first node driven by [param feature] (null if none)
func get_feature_node(feature : StringName) -> Node:
	var nodes := get_feature_nodes(feature)
	return nodes[0] if nodes.size() > 0 else null


## Returns every node driven by [param feature]
func get_feature_nodes(feature : StringName) -> Array[Node]:
	var nodes : Array[Node] = []
	var paths : Array = FEATURE_NODES.get(feature, SETTING_NODES.get(feature, []))
	for path : String in paths:
		var node := get_node_or_null(path)
		if node:
			nodes.append(node)
	return nodes


## Returns true if [param feature] is effectively active on this rig (the
## configuration value combined with the rules between features)
func is_feature_active(feature : StringName) -> bool:
	if not config.is_enabled(feature):
		return false
	if BODY_FEATURES.has(feature) and not config.is_enabled(&"player_body"):
		return false
	return true


## Apply the whole configuration
func _apply_all(p_startup : bool = false) -> void:
	for feature : StringName in FEATURE_NODES:
		var active := is_feature_active(feature)
		_apply_feature(feature, not active)
	for feature : StringName in SETTING_NODES:
		# Height calibration is one-shot; only apply it at startup or when
		# the setting itself changes
		if feature == &"height_calibration" and not p_startup:
			continue
		# Log boolean settings that are off; enum/int settings stay quiet
		var value : Variant = config.get(feature)
		_apply_setting(feature, value, value is bool and not value)
	_warn_if_no_body()
	features_applied.emit()


# Switch the nodes of one feature to its effective state
func _apply_feature(feature : StringName, log_it : bool = true) -> void:
	var active := is_feature_active(feature)
	var paths : Array = FEATURE_NODES[feature]
	for path : String in paths:
		var node := get_node_or_null(path)
		if not node:
			continue
		var node_active := _node_rule(feature, path, active)
		_set_node_active(node, node_active)
		if not node_active:
			_on_node_turned_off(feature, node)
		if log_it:
			_log(feature, "on" if node_active else "off", node)


# Per-node rules between features
func _node_rule(feature : StringName, path : String, active : bool) -> bool:
	match feature:
		&"crouch":
			# Flight uses B/Y on the left controller
			if path.begins_with("LeftHand") and is_feature_active(&"flight"):
				return false
		&"pockets":
			# Hip pockets ride on the player body
			if path.begins_with("PlayerBody") and not config.is_enabled(&"player_body"):
				return false
		&"teleport":
			return active and not _left_pointer_on_target and not _left_hand_holding
	return active


# Clean up state a node leaves behind when it is switched off at runtime
func _on_node_turned_off(feature : StringName, node : Node) -> void:
	match feature:
		&"pickup":
			# A disabled pickup never processes the grip release
			if node is XRToolsFunctionPickup:
				node.drop_object()
		&"crouch":
			# A disabled crouch provider never clears its height override
			var body := XRToolsPlayerBody.find_instance(self)
			if body:
				body.override_player_height(node)
		&"pointer":
			_left_pointer_on_target = false


# Apply a property-style setting
func _apply_setting(feature : StringName, value : Variant, log_it : bool = true) -> void:
	var nodes := get_feature_nodes(feature)
	match feature:
		&"strafe":
			for node in nodes:
				_set_scene_value(node, &"strafe", bool(value), false)
		&"turn_mode":
			for node in nodes:
				node.turn_mode = value
		&"vignette_auto_adjust":
			for node in nodes:
				node.auto_adjust = bool(value)
				node.radius = 1.0 if value else static_vignette_radius
		&"head_behavior":
			for node in nodes:
				node.head_behavior_mode = value
		&"height_calibration":
			for node in nodes:
				node.player_calibrate_height = bool(value)
		&"hand_models":
			for node in nodes:
				_set_hand_model_visible(node, bool(value))
		&"collision_hands":
			for node in nodes:
				node.mode = XRToolsCollisionHand.CollisionHandMode.COLLIDE if value \
						else XRToolsCollisionHand.CollisionHandMode.TELEPORT
		&"ranged_pickup":
			for node in nodes:
				_set_scene_value(node, &"ranged_enable", bool(value), false)
		&"laser_visible":
			for node in nodes:
				_set_scene_value(node, &"show_laser", bool(value),
						XRToolsFunctionPointer.LaserShow.HIDE)
		&"hand_tracking":
			for node in nodes:
				_update_hand_tracking(node as XRController3D)
		&"desktop_fallback":
			# Deferred: children cannot be added while the zone is entering the tree
			_update_desktop_fallback.call_deferred()
		_:
			push_warning("PlayerRig: no handler for setting '%s'" % feature)
			return

	if log_it:
		for node in nodes:
			_log(feature, str(value), node)


# Enable or disable a single node
func _set_node_active(node : Node, enabled : bool) -> void:
	if "enabled" in node:
		node.enabled = enabled
	else:
		node.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED

	# Hide visual nodes, except the player body (its children have own toggles)
	if node is Node3D and not node is XRToolsPlayerBody:
		node.visible = enabled


# Show or hide a hand model. The node keeps processing so the poke and the
# collision-hand finger shapes still follow the hand.
func _set_hand_model_visible(node : Node, shown : bool) -> void:
	if node is Node3D:
		node.visible = shown
	var tree := node.get_node_or_null("AnimationTree") as AnimationTree
	if tree:
		tree.active = shown


# Set a property to its scene value (when [param on]) or to [param off_value].
# The scene value is remembered the first time the property is overwritten.
func _set_scene_value(node : Node, property : StringName, on : bool, off_value : Variant) -> void:
	var key := "%s:%s" % [node.get_instance_id(), property]
	if not _scene_values.has(key):
		_scene_values[key] = node.get(property)
	node.set(property, _scene_values[key] if on else off_value)


# A controller driven by optical hand tracking is ignored (hidden, not
# processing) while hand_tracking is off; controllers are never affected.
func _update_hand_tracking(controller : XRController3D) -> void:
	if not controller:
		return
	var from_hands := _get_controller_profile(controller) == HAND_INTERACTION_PROFILE
	var ignore := from_hands and not config.is_enabled(&"hand_tracking")
	if ignore:
		controller.visible = false
		controller.process_mode = Node.PROCESS_MODE_DISABLED
	elif controller.process_mode == Node.PROCESS_MODE_DISABLED:
		# Give visibility back to XRNode3D's show_when_tracked logic
		controller.process_mode = Node.PROCESS_MODE_INHERIT
		controller.visible = controller.get_has_tracking_data() or not controller.show_when_tracked


# Interaction profile currently bound to a controller's tracker
func _get_controller_profile(controller : XRController3D) -> String:
	var tracker := XRServer.get_tracker(controller.tracker) as XRPositionalTracker
	return tracker.profile if tracker else ""


# Add or remove the keyboard/mouse fallback. It is only used when XR failed
# to start (no primary interface), never while a headset is in use.
func _update_desktop_fallback() -> void:
	var wanted := config.is_enabled(&"desktop_fallback") and XRServer.primary_interface == null
	if wanted and not is_instance_valid(_desktop_fallback):
		var scene := load(DESKTOP_FALLBACK_SCENE) as PackedScene
		if not scene:
			push_error("PlayerRig: cannot load %s" % DESKTOP_FALLBACK_SCENE)
			return
		_desktop_fallback = scene.instantiate()
		add_child(_desktop_fallback)
		_desktop_fallback.owner = owner if owner else self
		_refresh_movement_providers()
		_log(&"desktop_fallback", "added", _desktop_fallback)
	elif not wanted and is_instance_valid(_desktop_fallback):
		remove_child(_desktop_fallback)
		_desktop_fallback.queue_free()
		_desktop_fallback = null
		_refresh_movement_providers()


# The player body caches the movement providers in its _ready; refresh the
# list after providers were added or removed. (Deliberate access to the
# upstream private member, like PersistentZone's use of _pick_up_object.)
func _refresh_movement_providers() -> void:
	var body := XRToolsPlayerBody.find_instance(self)
	if not body:
		return
	var providers := get_tree().get_nodes_in_group("movement_providers").filter(
			func(p : Node) -> bool: return is_instance_valid(p) and not p.is_queued_for_deletion())
	providers.sort_custom(body.sort_by_order)
	body._movement_providers = providers


# Free the nodes of disabled features (remove_disabled_nodes). Runs in
# _enter_tree, before any child joined a group or ran _ready.
func _remove_disabled_nodes() -> void:
	for feature : StringName in FEATURE_NODES:
		if NEVER_FREE.has(feature) or is_feature_active(feature):
			continue
		for path : String in FEATURE_NODES[feature]:
			var node := get_node_or_null(path)
			if node:
				_log(feature, "removed", node)
				node.get_parent().remove_child(node)
				node.free()


# Connect the hand signals used by haptics and the teleport guard
func _connect_hand_signals() -> void:
	for pickup in get_feature_nodes(&"pickup"):
		var controller := XRHelpers.get_xr_controller(pickup)
		pickup.has_picked_up.connect(_on_pickup_picked_up.bind(controller))
		pickup.has_dropped.connect(_on_pickup_dropped.bind(controller))
	for pointer in get_feature_nodes(&"pointer"):
		pointer.pointing_event.connect(_on_pointing_event.bind(XRHelpers.get_xr_controller(pointer)))
	for controller in get_feature_nodes(&"hand_tracking"):
		controller.profile_changed.connect(_on_controller_profile_changed.bind(controller))


# Print a feature change in debug builds
func _log(feature : StringName, state : String, node : Node) -> void:
	if OS.is_debug_build():
		print("VRFeatures: %s -> %s (%s)" % [feature, state, node.name])


# Warn once when movement features are on but the player body is off
func _warn_if_no_body() -> void:
	if config.is_enabled(&"player_body") or _warned_no_body:
		return
	var forced : Array[StringName] = []
	for feature in BODY_FEATURES:
		if config.is_enabled(feature):
			forced.append(feature)
	if forced.is_empty():
		return
	_warned_no_body = true
	push_warning("PlayerRig: player_body is off, so these movement features are off too: %s. "
			% ", ".join(forced) + "Hip pockets and zone-switch areas also need the player body.")


# Report missing feature nodes (scene edited without updating FEATURE_NODES)
func _validate_paths() -> void:
	for path in get_missing_paths():
		# Nodes freed by remove_disabled_nodes are expected to be missing
		if config and config.remove_disabled_nodes:
			continue
		push_error("PlayerRig: feature node missing: %s" % path)


# Load the active configuration (VRFeatures, or the defaults)
func _load_config() -> VRFeatureConfig:
	var features := _get_features()
	if features:
		return features.config
	push_warning("PlayerRig: VRFeatures autoload not found; using default features")
	return VRFeatureConfig.new()


# Find the VRFeatures autoload without a hard dependency on it
func _get_features() -> Node:
	return get_node_or_null(^"/root/VRFeatures")


# Handle runtime changes of a single feature
func _on_feature_value_changed(feature : StringName, value : Variant) -> void:
	if FEATURE_NODES.has(feature):
		if get_feature_nodes(feature).is_empty():
			push_warning("PlayerRig: nodes of '%s' were removed at startup" % feature)
		else:
			_apply_feature(feature)
	elif SETTING_NODES.has(feature):
		_apply_setting(feature, value)

	# Re-apply features that depend on this one
	for dependent : StringName in DEPENDENTS.get(feature, []):
		_apply_feature(dependent, false)
	if feature == &"player_body":
		_warned_no_body = false
		_warn_if_no_body()


# Handle the whole configuration being replaced
func _on_config_replaced(p_config : VRFeatureConfig) -> void:
	config = p_config
	_warned_no_body = false
	_apply_all(false)


# Haptic tick when a hand picks something up
func _on_pickup_picked_up(_what : Variant, controller : XRController3D) -> void:
	if controller == _left_controller:
		_left_hand_holding = true
		_apply_feature(&"teleport", false)
	Haptics.tap(controller)


# Softer tick when a hand lets go
func _on_pickup_dropped(controller : XRController3D) -> void:
	if controller == _left_controller:
		_left_hand_holding = false
		_apply_feature(&"teleport", false)
	Haptics.pulse(controller, 0.25, 20, &"haptics_drop")


# Pointer events: haptic tick on press, teleport guard on enter/exit
func _on_pointing_event(event : XRToolsPointerEvent, controller : XRController3D) -> void:
	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			Haptics.tap(controller)
		XRToolsPointerEvent.Type.ENTERED, XRToolsPointerEvent.Type.EXITED:
			if controller == _left_controller:
				_left_pointer_on_target = event.event_type == XRToolsPointerEvent.Type.ENTERED
				_apply_feature(&"teleport", false)


# A controller switched between a controller profile and hand tracking
func _on_controller_profile_changed(_role : String, controller : XRController3D) -> void:
	_update_hand_tracking(controller)
