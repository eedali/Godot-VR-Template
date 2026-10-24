class_name FeatureGate
extends Node


## Feature Gate
##
## Ties zone content to a [VRFeatureConfig] toggle. Add it as a child of the
## node to control (a teleport area, a climbable wall, a world-grab area, a
## virtual keyboard, ...) and set [member feature]. While the feature is off
## the parent is hidden, its [code]enabled[/code] property (if any) is
## cleared and its processing is disabled, which also removes physics bodies
## and areas from the simulation (see [member CollisionObject3D.disable_mode]).
## Follows runtime changes made through [code]VRFeatures[/code].
##
## Signal callbacks keep working while the parent is disabled, so the gate
## can switch it back on.


## Name of the VRFeatureConfig setting controlling the parent
@export var feature : StringName = &""

## If true the parent is active while the feature is OFF
@export var invert : bool = false

## If true, the parent is freed at startup instead of disabled when the
## feature is off (cannot be switched back on)
@export var free_when_off : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var features := get_node_or_null(^"/root/VRFeatures")
	if not features or feature == &"":
		return
	if not features.config.has_feature(feature):
		push_warning("FeatureGate on %s: unknown feature '%s'" % [get_parent().name, feature])
		return

	var on := _is_on(features.is_enabled(feature))
	if not on and free_when_off:
		get_parent().queue_free.call_deferred()
		return

	features.value_changed.connect(_on_feature_value_changed)
	features.config_replaced.connect(_on_config_replaced)
	# Deferred so the parent's own _ready has run (children are ready first)
	_apply.call_deferred(on)


# Returns the parent state for a feature value
func _is_on(value : bool) -> bool:
	return value != invert


# Switch the parent on or off
func _apply(on : bool) -> void:
	var target := get_parent()
	if not is_instance_valid(target):
		return
	if "enabled" in target:
		target.enabled = on
	if target is Node3D:
		target.visible = on
	target.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func _on_feature_value_changed(p_feature : StringName, value : Variant) -> void:
	if p_feature == feature:
		_apply(_is_on(bool(value)))


func _on_config_replaced(config : VRFeatureConfig) -> void:
	_apply(_is_on(config.is_enabled(feature)))
