@tool
class_name PlayerRig
extends XROrigin3D


## Player Rig
##
## The complete VR player: XROrigin3D, camera, both hands (collision hands,
## hand models, poke, pointer, pickup), every movement provider, the player
## body with pockets and the wrist UI. Zones instance this scene as their
## [code]XROrigin3D[/code] node (see game/zones/zone_base.tscn).
##
## Which mechanics are active is decided by the [VRFeatureConfig] held by the
## [code]VRFeatures[/code] autoload. [constant FEATURE_NODES] maps each
## feature to the nodes it switches on/off; [constant SETTING_NODES] lists
## features that change a property of a node instead (each has a handler in
## [method _apply_setting]). The rig follows runtime changes made through
## [code]VRFeatures.set_enabled()[/code] / [code]set_value()[/code].


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
	&"direct_movement": [
		"LeftHand/CollisionHandLeft/MovementDirect",
		"RightHand/CollisionHandRight/MovementDirect",
	],
	&"turn": [
		"RightHand/CollisionHandRight/MovementTurn",
	],
	&"jump": [
		"LeftHand/CollisionHandLeft/MovementJump",
		"RightHand/CollisionHandRight/MovementJump",
	],
	&"crouch": [
		"LeftHand/CollisionHandLeft/MovementCrouch",
		"RightHand/CollisionHandRight/MovementCrouch",
	],
	&"sprint": [
		"MovementSprint",
	],
	&"player_body": [
		"PlayerBody",
	],
	&"pickup": [
		"LeftHand/CollisionHandLeft/FunctionPickup",
		"RightHand/CollisionHandRight/FunctionPickup",
	],
	&"pointer": [
		"LeftHand/CollisionHandLeft/FunctionPointer",
		"RightHand/CollisionHandRight/FunctionPointer",
	],
	&"poke": [
		LEFT_TIP + "/Poke",
		RIGHT_TIP + "/Poke",
	],
	&"pockets": [
		"XRCamera3D/BackPocket",
		"PlayerBody/LeftPocket",
		"PlayerBody/RightPocket",
	],
	&"wrist_ui": [
		"LeftHand/CollisionHandLeft/WristUI",
	],
}

## Features that modify properties of nodes (handled in [method _apply_setting])
const SETTING_NODES : Dictionary = {
	&"strafe": [
		"LeftHand/CollisionHandLeft/MovementDirect",
	],
	&"turn_mode": [
		"RightHand/CollisionHandRight/MovementTurn",
	],
	&"head_behavior": [
		"PlayerBody",
	],
	&"height_calibration": [
		"PlayerBody",
	],
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
}

## Features whose nodes are never freed by remove_disabled_nodes (other
## systems hold references to them, e.g. GameState needs the PlayerBody)
const NEVER_FREE : Array[StringName] = [
	&"player_body",
]


## Configuration currently applied to this rig
var config : VRFeatureConfig

# Scene values of properties the settings overwrite, keyed by node + property,
# so switching a setting back restores what the scene designer chose.
var _scene_values : Dictionary = {}


# Add support for is_xr_class on XRTools classes
func is_xr_class(p_name : String) -> bool:
	return p_name == "PlayerRig"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_validate_paths()

	var features := _get_features()
	if features:
		config = features.config
		features.value_changed.connect(_on_feature_value_changed)
		features.config_replaced.connect(_on_config_replaced)
	else:
		push_warning("PlayerRig: VRFeatures autoload not found; using default features")
		config = VRFeatureConfig.new()

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
	var paths : Array = FEATURE_NODES.get(feature, SETTING_NODES.get(feature, []))
	for path : String in paths:
		var node := get_node_or_null(path)
		if node:
			return node
	return null


## Returns every node driven by [param feature]
func get_feature_nodes(feature : StringName) -> Array[Node]:
	var nodes : Array[Node] = []
	var paths : Array = FEATURE_NODES.get(feature, SETTING_NODES.get(feature, []))
	for path : String in paths:
		var node := get_node_or_null(path)
		if node:
			nodes.append(node)
	return nodes


## Apply the whole configuration. When [param p_startup] is true and the
## configuration asks for it, nodes of disabled features are freed.
func _apply_all(p_startup : bool = false) -> void:
	var free_disabled := p_startup and config.remove_disabled_nodes
	for feature : StringName in FEATURE_NODES:
		var enabled := config.is_enabled(feature)
		if free_disabled and not enabled and not NEVER_FREE.has(feature):
			for node in get_feature_nodes(feature):
				_log(feature, "removed", node)
				node.queue_free()
			continue
		_apply_feature(feature, enabled, not enabled)
	for feature : StringName in SETTING_NODES:
		# Log boolean settings that are off; enum/int settings stay quiet
		var value : Variant = config.get(feature)
		_apply_setting(feature, value, value is bool and not value)
	features_applied.emit()


# Switch the nodes of one feature on or off
func _apply_feature(feature : StringName, enabled : bool, log_it : bool = true) -> void:
	for node in get_feature_nodes(feature):
		_set_node_active(node, enabled)
		if log_it:
			_log(feature, "on" if enabled else "off", node)


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


# Print a feature change in debug builds
func _log(feature : StringName, state : String, node : Node) -> void:
	if OS.is_debug_build():
		print("VRFeatures: %s -> %s (%s)" % [feature, state, node.name])


# Report missing feature nodes (scene edited without updating FEATURE_NODES)
func _validate_paths() -> void:
	for path in get_missing_paths():
		push_error("PlayerRig: feature node missing: %s" % path)


# Find the VRFeatures autoload without a hard dependency on it
func _get_features() -> Node:
	return get_node_or_null(^"/root/VRFeatures")


# Handle runtime changes of a single feature
func _on_feature_value_changed(feature : StringName, value : Variant) -> void:
	if FEATURE_NODES.has(feature):
		var nodes := get_feature_nodes(feature)
		if nodes.is_empty():
			push_warning("PlayerRig: nodes of '%s' were removed at startup" % feature)
			return
		_apply_feature(feature, bool(value))
	elif SETTING_NODES.has(feature):
		_apply_setting(feature, value)


# Handle the whole configuration being replaced
func _on_config_replaced(p_config : VRFeatureConfig) -> void:
	config = p_config
	_apply_all(false)
