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
##
## Feature overrides (applied through VRFeatures before the game starts):
##   ... --script res://tools/zone_load_test.gd -- --set=player_body=false,climb=true
##   ... --script res://tools/zone_load_test.gd -- --set=all_on


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
	_apply_overrides()
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
	_check_trigger_rules(game_state)

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

	await _check_showcase_entry_points(game_state, staging, first_zone)
	_finish()


# The wrist menu "Showcase" button (from another zone) and the start menu
# "Showcase" button (after quitting to the menu) must both reach the showcase
func _check_showcase_entry_points(game_state : Node, staging : Node, first_zone : Resource) -> void:
	staging.load_scene(first_zone.instance_scene)
	if not await _wait_for_zone(game_state, first_zone.zone_id):
		return
	var wrist_ui : Node = game_state.current_zone.get_node_or_null(
			"XROrigin3D/LeftHand/CollisionHandLeft/WristUI")
	if wrist_ui and wrist_ui.get_scene_instance():
		wrist_ui.get_scene_instance()._on_showcase_button_pressed()
		if await _wait_for_zone(game_state, "zone_showcase"):
			print("zone_load_test: wrist menu -> showcase ok")
	else:
		print("zone_load_test: wrist menu check skipped (no wrist UI)")

	var visible_before := _visible_scenes
	if not game_state.quit_game():
		_fail("GameState.quit_game() returned false")
		return
	if not await _wait_for_visible(visible_before + 1, "start scene after quit"):
		return
	var start_ui : Node = staging.current_scene.get_node("Screen").get_scene_instance()
	start_ui._on_showcase_btn_pressed()
	if await _wait_for_zone(game_state, "zone_showcase"):
		print("zone_load_test: start menu -> showcase ok")


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
	# remove_disabled_nodes frees the nodes of disabled features on purpose
	if not rig.config.remove_disabled_nodes:
		for path in rig.get_missing_paths():
			_fail("%s: feature node missing: %s" % [zone.zone_info.zone_id, path])
	if get_nodes_in_group("player_body").is_empty():
		_fail("%s: no XRToolsPlayerBody" % zone.zone_info.zone_id)

	# Without a headset the rig must add the keyboard/mouse fallback, and the
	# player body must drive its movement providers
	var features : Node = root.get_node("VRFeatures")
	if features.is_enabled(&"desktop_fallback") and XRServer.primary_interface == null:
		var fallback : Node = rig.get_node_or_null("DesktopFallback")
		if not fallback:
			_fail("%s: desktop fallback not added" % zone.zone_info.zone_id)
		else:
			var body : Node = rig.get_node("PlayerBody")
			var direct : Node = fallback.get_node("MovementDesktopDirect")
			if not body._movement_providers.has(direct):
				_fail("%s: desktop movement not registered with the body" % zone.zone_info.zone_id)


# Switch a feature at runtime and verify the rig follows
func _check_runtime_toggle(game_state : Node) -> void:
	var features : Node = root.get_node("VRFeatures")
	var rig : Node = game_state.current_zone.get_node("XROrigin3D")

	# Pick a feature whose node still exists (remove_disabled_nodes may have
	# freed some) and that is not forced off by another feature
	var feature := &""
	for candidate : StringName in [&"direct_movement", &"pointer", &"wrist_ui"]:
		var forced_off : bool = candidate == &"direct_movement" \
				and not features.is_enabled(&"player_body")
		if rig.get_feature_node(candidate) and not forced_off:
			feature = candidate
			break
	if feature == &"":
		print("zone_load_test: runtime toggle skipped (no switchable node left)")
		return

	var node : Node = rig.get_feature_node(feature)
	var initial : bool = features.is_enabled(feature)
	for value : bool in [not initial, initial]:
		features.set_enabled(feature, value)
		await process_frame
		if node.enabled != rig.is_feature_active(feature) or node.enabled != value:
			_fail("runtime toggle of %s to %s did not reach the rig" % [feature, value])
	print("zone_load_test: runtime toggle ok (%s)" % feature)


# Aiming the teleport (left trigger) pauses left-stick movement, and a
# teleport tells the vignette to skip the jump
func _check_trigger_rules(game_state : Node) -> void:
	var rig : Node = game_state.current_zone.get_node("XROrigin3D")
	var teleport : Node = rig.get_feature_node(&"teleport")
	var direct : Node = rig.get_node_or_null("LeftHand/CollisionHandLeft/MovementDirect")
	if not teleport or not direct or not teleport.enabled or not direct.enabled:
		print("zone_load_test: trigger rules skipped (teleport or direct movement off)")
		return

	var left : Node = rig.get_node("LeftHand")
	left.button_pressed.emit(teleport.teleport_button_action)
	if direct.enabled:
		_fail("left stick movement still on while the teleport aims")
	left.button_released.emit(teleport.teleport_button_action)
	if not direct.enabled:
		_fail("left stick movement not restored after teleport aiming")

	var vignette : Node = rig.get_feature_node(&"vignette")
	if vignette:
		vignette.auto_first = false
		var body : Node = rig.get_node("PlayerBody")
		body.teleport(body.global_transform)
		if not vignette.auto_first:
			_fail("vignette not reset after a teleport")
	print("zone_load_test: trigger rules ok")


# Apply "--set=name=value,..." / "--set=all_on" from the user command line
func _apply_overrides() -> void:
	var features : Node = root.get_node("VRFeatures")
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--set="):
			continue
		for item in arg.trim_prefix("--set=").split(",", false):
			if item == "all_on":
				for feature : StringName in features.config.get_feature_names():
					if features.config.get(feature) is bool and feature != &"remove_disabled_nodes":
						features.set_value(feature, true)
				continue
			var parts := item.split("=")
			if parts.size() != 2:
				_fail("bad override: " + item)
				continue
			var text := parts[1].strip_edges()
			var value : Variant = text.to_int() if text.is_valid_int() else text == "true"
			features.set_value(StringName(parts[0].strip_edges()), value)
		print("zone_load_test: overrides ", arg)


# Wait until [param condition] returns true (polling every 0.1 s)
func _wait_for(condition : Callable, what : String) -> bool:
	var waited := 0.0
	while not condition.call():
		_press_continue_if_prompted()
		if waited > STEP_TIMEOUT:
			var staging : Node = current_scene
			_fail("timeout waiting for %s (staging scene: %s)" % [
				what, staging.get("current_scene_path") if staging else "none"])
			return false
		await create_timer(0.1).timeout
		waited += 0.1
	return true


# The loading screen waits for "hold to continue" on the first load (and on
# every load with loading_prompt on); press it like a player would
func _press_continue_if_prompted() -> void:
	var staging : Node = current_scene
	if not staging or not staging.has_node("LoadingScreen"):
		return
	var loading_screen : Node = staging.get_node("LoadingScreen")
	if loading_screen.visible and loading_screen.enable_press_to_continue:
		loading_screen.continue_pressed.emit()


func _on_scene_visible(_scene : Node, _user_data : Variant) -> void:
	_visible_scenes += 1


func _fail(message : String) -> void:
	_failures.append(message)
	printerr("FAIL: " + message)


func _finish() -> void:
	print("zone_load_test: %d failure(s)" % _failures.size())
	quit(1 if _failures.size() > 0 else 0)
