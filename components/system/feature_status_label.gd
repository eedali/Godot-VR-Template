class_name FeatureStatusLabel
extends Label3D


## Feature Status Label
##
## A [Label3D] that shows a title followed by the live on/off state of a list
## of [VRFeatureConfig] settings, e.g. above a showcase station:
## [codeblock]
## Locomotion
## teleport: on   climb: off
## [/codeblock]
## Updates only when [code]VRFeatures[/code] reports a change.


## First line of the label
@export var title : String = ""

## Settings whose state is listed
@export var features : Array[StringName] = []

## Settings shown per line
@export_range(1, 6) var per_line : int = 3


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var vr_features := get_node_or_null(^"/root/VRFeatures")
	if vr_features:
		vr_features.value_changed.connect(_on_value_changed)
		vr_features.config_replaced.connect(_on_config_replaced)
	_refresh()


func _refresh() -> void:
	var vr_features := get_node_or_null(^"/root/VRFeatures")
	var lines : PackedStringArray = [title] if title != "" else []
	var line : PackedStringArray = []
	for feature in features:
		var state := "?"
		if vr_features:
			var value : Variant = vr_features.get_value(feature)
			state = ("on" if value else "off") if value is bool else str(value)
		line.append("%s: %s" % [feature, state])
		if line.size() >= per_line:
			lines.append("   ".join(line))
			line.clear()
	if not line.is_empty():
		lines.append("   ".join(line))
	text = "\n".join(lines)


func _on_value_changed(feature : StringName, _value : Variant) -> void:
	if features.has(feature):
		_refresh()


func _on_config_replaced(_config : VRFeatureConfig) -> void:
	_refresh()
