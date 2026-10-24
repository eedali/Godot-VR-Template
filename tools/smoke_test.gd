extends SceneTree


## Headless smoke test
##
## Loads every .tscn / .tres / .gd under the scanned folders, instantiates
## every PackedScene (without adding it to the tree, so no _ready runs) and
## re-parses every GDScript. Any failure is reported and the process exits
## with code 1.
##
## Run with:
##   bash tools/godot.sh --headless --path . --script res://tools/smoke_test.gd


## Folders scanned recursively (addons are upstream and intentionally skipped)
const SCAN_DIRS : Array[String] = [
	"res://game",
	"res://components",
	"res://config",
]

## Extra single files that must always load
const EXTRA_FILES : Array[String] = [
	"res://project.godot",
	"res://openxr_action_map.tres",
	"res://default_env.tres",
]

## Every VRFeatureConfig setting named in docs/claude/FEATURES.md (plus the
## behaviour switch from ARCHITECTURE.md). Renaming or dropping a toggle fails
## the smoke test; add new toggles here and to FEATURES.md together.
const REQUIRED_FEATURES : Array[StringName] = [
	# Locomotion
	&"direct_movement", &"strafe", &"turn", &"turn_mode", &"teleport", &"jump",
	&"physical_jump", &"crouch", &"sprint", &"jog", &"climb", &"flight", &"glide",
	&"grapple", &"wall_walk", &"world_grab", &"wind", &"footsteps",
	# Comfort
	&"vignette", &"vignette_auto_adjust", &"head_behavior", &"height_calibration",
	&"player_body", &"loading_prompt",
	# Hands & interaction
	&"hand_models", &"collision_hands", &"pickup", &"ranged_pickup", &"pointer",
	&"laser_visible", &"gaze_pointer", &"poke", &"pockets", &"wrist_ui",
	&"hand_pose_areas", &"haptics", &"virtual_keyboard",
	# System
	&"hand_tracking", &"passthrough", &"desktop_fallback", &"debug_hud",
	&"target_refresh_rate", &"physics_rate_multiplier",
	# Behaviour
	&"remove_disabled_nodes",
]

## Minimum number of settings the feature configuration must expose
const MIN_FEATURE_COUNT : int = 40

## Player rig scene whose FEATURE_NODES / SETTING_NODES paths must all exist
const PLAYER_RIG_SCENE := "res://components/player/player_rig.tscn"

## Script and default resource of the feature configuration
const FEATURE_CONFIG_SCRIPT := "res://config/vr_feature_config.gd"
const FEATURE_CONFIG_DEFAULT := "res://config/vr_features_default.tres"

var _failures : Array[String] = []
var _checked : int = 0


func _init() -> void:
	# Defer so the SceneTree is fully constructed before we load resources
	_run.call_deferred()


func _run() -> void:
	for dir in SCAN_DIRS:
		_scan(dir)
	for file in EXTRA_FILES:
		if file.ends_with(".godot"):
			if not FileAccess.file_exists(file):
				_failures.append(file + " (missing)")
			continue
		_check(file)

	_check_feature_config()
	_check_player_rig()

	print("smoke_test: %d files checked, %d failure(s)" % [_checked, _failures.size()])
	for failure in _failures:
		printerr("FAIL: " + failure)

	quit(1 if _failures.size() > 0 else 0)


func _scan(path : String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		# A scanned folder may not exist yet (e.g. res://config before phase 2)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := path.path_join(name)
		if dir.current_is_dir():
			if not name.begins_with("."):
				_scan(full)
		elif name.ends_with(".tscn") or name.ends_with(".tres") or name.ends_with(".gd"):
			_check(full)
		name = dir.get_next()
	dir.list_dir_end()


func _check(path : String) -> void:
	_checked += 1
	if not ResourceLoader.exists(path):
		_failures.append(path + " (ResourceLoader.exists == false)")
		return

	# Every ext_resource the file references must exist (Godot otherwise loads
	# the file with a missing dependency and only prints an error).
	for dep in ResourceLoader.get_dependencies(path):
		if not _dependency_exists(dep):
			_failures.append(path + " (missing dependency: %s)" % dep)

	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	if res == null:
		_failures.append(path + " (load returned null)")
		return

	if res is PackedScene:
		var scene := res as PackedScene
		if not scene.can_instantiate():
			_failures.append(path + " (PackedScene.can_instantiate == false)")
			return
		var inst := scene.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
		if inst == null:
			_failures.append(path + " (instantiate returned null)")
			return
		inst.free()
	elif res is GDScript:
		var script := res as GDScript
		# A script with compile errors still loads, but cannot be instantiated.
		if not script.can_instantiate() and not script.is_abstract():
			_failures.append(path + " (script does not compile)")


## Dependency strings are "uid::type::path" (or just a path); any slice that
## starts with res:// is the path, any slice that starts with uid:// is the uid.
func _dependency_exists(dep : String) -> bool:
	var dep_path := ""
	var dep_uid := ""
	for i in dep.get_slice_count("::"):
		var part := dep.get_slice("::", i)
		if part.begins_with("res://"):
			dep_path = part
		elif part.begins_with("uid://"):
			dep_uid = part
	if dep_path != "" and ResourceLoader.exists(dep_path):
		return true
	if dep_uid != "":
		var id := ResourceUID.text_to_id(dep_uid)
		if id != ResourceUID.INVALID_ID and ResourceUID.has_id(id):
			return ResourceLoader.exists(ResourceUID.get_id_path(id))
	return false


## The feature configuration must expose every required toggle, and the
## shipped default resource must load as that class.
func _check_feature_config() -> void:
	var script := load(FEATURE_CONFIG_SCRIPT) as GDScript
	if not script or not script.can_instantiate():
		_failures.append(FEATURE_CONFIG_SCRIPT + " (cannot instantiate VRFeatureConfig)")
		return

	var config : Resource = script.new()
	var names : Array = config.get_feature_names()
	for feature in REQUIRED_FEATURES:
		if not names.has(feature):
			_failures.append(FEATURE_CONFIG_SCRIPT + " (missing feature toggle: %s)" % feature)
	if names.size() < MIN_FEATURE_COUNT:
		_failures.append(FEATURE_CONFIG_SCRIPT + " (only %d settings, expected >= %d)" % [
			names.size(), MIN_FEATURE_COUNT])

	var defaults := load(FEATURE_CONFIG_DEFAULT)
	if not defaults or defaults.get_script() != script:
		_failures.append(FEATURE_CONFIG_DEFAULT + " (not a VRFeatureConfig)")
	print("smoke_test: VRFeatureConfig exposes %d settings" % names.size())

	# The autoload must be registered and answer queries
	var features := root.get_node_or_null("VRFeatures")
	if not features or not features.has_method("is_enabled"):
		_failures.append("project.godot (VRFeatures autoload missing)")
	elif not features.config or features.config.get_script() != script:
		_failures.append("VRFeatures (active config is not a VRFeatureConfig)")


## Instantiate the player rig and assert every feature node path exists, so a
## renamed or moved node fails the check instead of silently disabling a
## feature at runtime.
func _check_player_rig() -> void:
	var scene := load(PLAYER_RIG_SCENE) as PackedScene
	if not scene:
		_failures.append(PLAYER_RIG_SCENE + " (cannot load)")
		return
	var rig := scene.instantiate()
	if not rig or not rig.has_method("get_all_feature_paths"):
		_failures.append(PLAYER_RIG_SCENE + " (root is not a PlayerRig)")
		if rig:
			rig.free()
		return

	var config : Resource = load(FEATURE_CONFIG_SCRIPT).new()
	var paths : Array = rig.get_all_feature_paths()
	for path : String in paths:
		if not rig.has_node(path):
			_failures.append(PLAYER_RIG_SCENE + " (feature node missing: %s)" % path)
	for table : Dictionary in [rig.FEATURE_NODES, rig.SETTING_NODES, rig.EXTERNAL_FEATURES]:
		for feature : StringName in table:
			if not config.has_feature(feature):
				_failures.append(PLAYER_RIG_SCENE + " (unknown feature in rig: %s)" % feature)

	# Every toggle must have a node, a handler or a documented external owner
	for feature : StringName in config.get_feature_names():
		var handled : bool = rig.FEATURE_NODES.has(feature) or rig.SETTING_NODES.has(feature) \
				or rig.EXTERNAL_FEATURES.has(feature)
		if not handled:
			_failures.append(PLAYER_RIG_SCENE + " (feature not handled anywhere: %s)" % feature)
	for table : Dictionary in [rig.REQUIRES, rig.NODE_RULE_SOURCES]:
		for feature : StringName in table:
			for other : StringName in [feature] + Array(table[feature]):
				if not config.has_feature(other):
					_failures.append(PLAYER_RIG_SCENE + " (unknown feature in rules: %s)" % other)
	print("smoke_test: PlayerRig has %d feature node paths" % paths.size())
	rig.free()
