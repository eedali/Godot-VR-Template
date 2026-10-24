class_name FeatureToggleButton
extends Node


## Feature Toggle Button
##
## Flips a boolean [VRFeatureConfig] feature at runtime whenever a button
## emits its press signal. Works with [XRToolsInteractableAreaButton]
## ([code]button_pressed[/code]), 2D [BaseButton]s ([code]pressed[/code]) and
## anything else exposing one of those signals. Used by the showcase kiosk;
## handy for debug menus in games too.


## Feature to toggle
@export var feature : StringName = &""

## Node whose press signal toggles the feature (default: the parent)
@export var button : NodePath = ^".."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var target := get_node_or_null(button)
	if not target:
		push_warning("FeatureToggleButton: button node not found: %s" % button)
		return
	if target.has_signal("button_pressed"):
		target.connect("button_pressed", _on_pressed.unbind(1))
	elif target.has_signal("pressed"):
		target.connect("pressed", _on_pressed)
	else:
		push_warning("FeatureToggleButton: %s has no press signal" % target.name)


func _on_pressed() -> void:
	var features := get_node_or_null(^"/root/VRFeatures")
	if not features or not features.config.has_feature(feature):
		push_warning("FeatureToggleButton: unknown feature '%s'" % feature)
		return
	features.set_enabled(feature, not features.is_enabled(feature))
