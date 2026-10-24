@tool
class_name GameStaging
extends PersistentStaging


## Game Staging Script
##
## This script registers the staging instance with the [GameState] singleton
## and handles pausing/resuming.
##
## It also applies the staging-level settings of the feature configuration,
## which must be in place before the first zone loads (the start scene has no
## [PlayerRig]):
## [code]target_refresh_rate[/code] and [code]physics_rate_multiplier[/code]
## (forwarded to [code]StartXR[/code]) and [code]loading_prompt[/code].


# Called when the node enters the scene tree for the first time.
func _ready():
	super()

	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# Connect events
	scene_loaded.connect(_on_scene_loaded)
	xr_started.connect(_on_xr_started)
	xr_ended.connect(_on_xr_ended)

	# Apply the staging-level feature settings and follow runtime changes.
	# StartXR applies the rates when the OpenXR session begins, which is after
	# this _ready.
	var features := get_node_or_null(^"/root/VRFeatures")
	if features:
		_apply_xr_rates(features.config)
		features.value_changed.connect(_on_feature_value_changed)
		features.config_replaced.connect(_apply_xr_rates)


# This method is called when a scene is loaded
func _on_scene_loaded(_scene : XRToolsSceneBase, _user_data : Variant) -> void:
	# Clear the continue prompt (only the first load prompts) unless the
	# feature configuration asks for a prompt on every load
	var features := get_node_or_null(^"/root/VRFeatures")
	prompt_for_continue = features != null and features.is_enabled(&"loading_prompt")


# This method is called when the player starts the VR experience
func _on_xr_started() -> void:
	# Resume the game
	get_tree().paused = false


# This method is called when the player ends the VR experience
func _on_xr_ended() -> void:
	# Pause the game
	get_tree().paused = true


# Forward the refresh/physics rate settings to StartXR
func _apply_xr_rates(config : VRFeatureConfig) -> void:
	var start_xr := get_node_or_null(^"StartXR")
	if not start_xr:
		return
	start_xr.target_refresh_rate = config.target_refresh_rate
	start_xr.physics_rate_multiplier = maxi(config.physics_rate_multiplier, 1)

	# If the session is already running, re-apply now (StartXR only applies
	# the rates when the session begins)
	if start_xr.is_xr_active() and start_xr.xr_interface:
		start_xr._set_xr_frame_rate()


func _on_feature_value_changed(feature : StringName, _value : Variant) -> void:
	if feature == &"target_refresh_rate" or feature == &"physics_rate_multiplier":
		var features := get_node_or_null(^"/root/VRFeatures")
		if features:
			_apply_xr_rates(features.config)
