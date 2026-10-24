extends SceneTree


## Headless zone-load test
##
## Runs the real game flow without a headset: loads the main (staging) scene,
## presses "continue" on the first loading screen, starts a new game from the
## start menu path ([code]GameState.new_game()[/code]) and then loads every
## zone in the zone database. For every zone it checks that the PlayerRig is
## in place with all feature nodes, that a runtime feature toggle reaches the
## rig, and that the world state can be saved. Exits with code 1 on failure.
##
## Run with:
##   bash tools/godot.sh --headless --xr-mode off --path . --script res://tools/zone_load_test.gd


# This script is compiled before the autoloads exist, so it must not name
# project or XR Tools classes directly (their scripts use XRToolsUserSettings).
# Everything below is untyped / duck-typed on purpose.

## Seconds to wait for each step before failing
const STEP_TIMEOUT : float = 30.0

var _failures : Array[String] = []

# Number of scenes the staging reported as fully visible (faded in)
var _visible_scenes : int = 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file("res://game/main.tscn")

	# Staging
	var has_staging := func() -> bool:
		return current_scene != null and current_scene.has_method("load_scene")
	if not await _wait_for(has_staging, "staging"):
		_finish()
		return
	var staging : Node = current_scene
	staging.scene_visible.connect(_on_scene_visible)

	# Start scene (press "continue" on the first loading screen)
	var loading_screen : Node = staging.get_node("LoadingScreen")
	var prompt_or_visible := func() -> bool:
		return loading_screen.enable_press_to_continue or _visible_scenes >= 1
	await _wait_for(prompt_or_visible, "loading screen")
	if loading_screen.enable_press_to_continue:
		loading_screen.continue_pressed.emit()
	if not await _wait_for_visible(1, "start scene"):
		_finish()
		return
	print("zone_load_test: start scene loaded: ", staging.current_scene_path)

	# New game from the start menu path
	var game_state : Node = root.get_node("GameState")
	if not game_state.new_game():
		_fail("GameState.new_game() returned false")
		_finish()
		return
	var first_zone : Resource = game_state.starting_zone
	if not await _wait_for_zone(game_state, first_zone.zone_id):
		_finish()
		return
	_check_zone(game_state)
	await _check_runtime_toggle(game_state)

	# Every other zone in the database
	for zone : Resource in game_state.zone_database.zones:
		if zone.zone_id == first_zone.zone_id:
			continue
		staging.load_scene(zone.instance_scene)
		if not await _wait_for_zone(game_state, zone.zone_id):
			continue
		_check_zone(game_state)

	# Saving the world state must work from inside a zone
	if not game_state.save_world_state():
		_fail("GameState.save_world_state() returned false")

	_finish()


# Wait until the GameState reports the given zone as current and it has
# faded in (so the next load does not interrupt the transition)
func _wait_for_zone(game_state : Node, zone_id : String) -> bool:
	var visible_before := _visible_scenes
	var is_current := func() -> bool:
		var zone = game_state.current_zone
		return is_instance_valid(zone) and zone.zone_info and zone.zone_info.zone_id == zone_id
	if not await _wait_for(is_current, "zone " + zone_id):
		return false
	if not await _wait_for_visible(visible_before + 1, "zone %s fade-in" % zone_id):
		return false
	print("zone_load_test: zone loaded: ", zone_id)
	return true


# Wait until [param count] scenes have become visible
func _wait_for_visible(count : int, what : String) -> bool:
	return await _wait_for(func() -> bool: return _visible_scenes >= count, what)


# Check the rig of the current zone
func _check_zone(game_state : Node) -> void:
	var zone : Node = game_state.current_zone
	var rig : Node = zone.get_node_or_null("XROrigin3D")
	if not rig or not rig.has_method("get_missing_paths"):
		_fail("%s: XROrigin3D is not a PlayerRig" % zone.zone_info.zone_id)
		return
	for path in rig.get_missing_paths():
		_fail("%s: feature node missing: %s" % [zone.zone_info.zone_id, path])
	if get_nodes_in_group("player_body").is_empty():
		_fail("%s: no XRToolsPlayerBody" % zone.zone_info.zone_id)


# Switch a feature at runtime and verify the rig follows
func _check_runtime_toggle(game_state : Node) -> void:
	var features : Node = root.get_node("VRFeatures")
	var rig : Node = game_state.current_zone.get_node("XROrigin3D")
	var direct : Node = rig.get_feature_node(&"direct_movement")
	var initial : bool = features.is_enabled(&"direct_movement")
	features.set_enabled(&"direct_movement", not initial)
	await process_frame
	if direct.enabled == initial:
		_fail("runtime toggle of direct_movement did not reach the rig")
	features.set_enabled(&"direct_movement", initial)
	await process_frame
	if direct.enabled != initial:
		_fail("restoring direct_movement did not reach the rig")
	print("zone_load_test: runtime toggle ok")


# Wait until [param condition] returns true (polling every 0.1 s)
func _wait_for(condition : Callable, what : String) -> bool:
	var waited := 0.0
	while not condition.call():
		if waited > STEP_TIMEOUT:
			var staging : Node = current_scene
			_fail("timeout waiting for %s (staging scene: %s)" % [
				what, staging.get("current_scene_path") if staging else "none"])
			return false
		await create_timer(0.1).timeout
		waited += 0.1
	return true


func _on_scene_visible(_scene : Node, _user_data : Variant) -> void:
	_visible_scenes += 1


func _fail(message : String) -> void:
	_failures.append(message)
	printerr("FAIL: " + message)


func _finish() -> void:
	print("zone_load_test: %d failure(s)" % _failures.size())
	quit(1 if _failures.size() > 0 else 0)
