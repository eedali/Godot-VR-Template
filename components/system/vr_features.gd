extends Node


## VR Features autoload ("VRFeatures")
##
## Holds the active [VRFeatureConfig] and broadcasts changes so every
## [PlayerRig] (and any game code) can react at runtime.
##
## The configuration file is read from the project setting
## [code]vr_template/feature_config[/code] (falls back to
## [code]res://config/vr_features_default.tres[/code]). The loaded resource is
## duplicated, so runtime changes never modify the .tres on disk.
##
## [codeblock]
## if VRFeatures.is_enabled(&"teleport"):
##     ...
## VRFeatures.set_enabled(&"vignette", false)
## [/codeblock]


## Emitted when a boolean feature is switched on or off
signal feature_changed(feature : StringName, enabled : bool)

## Emitted when any setting (boolean or not) changes value
signal value_changed(feature : StringName, value : Variant)

## Emitted when the whole configuration is replaced
signal config_replaced(config : VRFeatureConfig)


## Project setting holding the path of the active configuration resource
const SETTING_PATH := "vr_template/feature_config"

## Configuration used when the project setting is missing
const DEFAULT_PATH := "res://config/vr_features_default.tres"


## Active configuration (a runtime copy of the configured resource)
var config : VRFeatureConfig


func _init() -> void:
	# Load as early as possible so other autoloads and the first scene can
	# query features from their own _ready.
	config = load_config()


## Load the configuration named by the project setting. Never returns null.
static func load_config() -> VRFeatureConfig:
	var path : String = ProjectSettings.get_setting(SETTING_PATH, DEFAULT_PATH)
	var loaded : VRFeatureConfig = null
	if ResourceLoader.exists(path):
		loaded = load(path) as VRFeatureConfig
	if not loaded:
		push_warning("VRFeatures: cannot load '%s' as VRFeatureConfig; using defaults" % path)
		return VRFeatureConfig.new()
	return loaded.duplicate(true) as VRFeatureConfig


## Returns true if [param feature] is switched on
func is_enabled(feature : StringName) -> bool:
	return config.is_enabled(feature)


## Returns the raw value of [param feature] (null if unknown)
func get_value(feature : StringName) -> Variant:
	return config.get(feature)


## Switch a boolean feature on or off
func set_enabled(feature : StringName, enabled : bool) -> void:
	set_value(feature, enabled)


## Change the value of any setting
func set_value(feature : StringName, value : Variant) -> void:
	if not config.has_feature(feature):
		push_warning("VRFeatures: unknown feature '%s'" % feature)
		return

	# Convert to the type of the setting so "teleport = 1" still means true
	var old : Variant = config.get(feature)
	var new_value : Variant = type_convert(value, typeof(old))
	if new_value == old:
		return

	config.set(feature, new_value)
	value_changed.emit(feature, new_value)
	if new_value is bool:
		feature_changed.emit(feature, new_value)


## Replace the active configuration (e.g. per-level overrides). The resource
## is duplicated; [signal config_replaced] lets rigs re-apply everything.
func replace_config(p_config : VRFeatureConfig) -> void:
	if not p_config:
		push_warning("VRFeatures: replace_config called with null")
		return
	config = p_config.duplicate(true) as VRFeatureConfig
	config_replaced.emit(config)
