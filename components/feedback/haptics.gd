class_name Haptics
extends RefCounted


## Haptics helper
##
## Thin static wrapper over the [code]XRToolsRumbleManager[/code] autoload.
## Every call is ignored when the [code]haptics[/code] feature is off; the
## user's haptics scale (Options menu) is applied by the rumble manager.
##
## [codeblock]
## Haptics.tap(controller)                         # short click
## Haptics.pulse(controller, 0.8, 120)             # stronger, longer
## Haptics.play(controller, preload("res://my_rumble.tres"))
## [/codeblock]


## Default short "tap" event
const TAP_EVENT : XRToolsRumbleEvent = preload("res://components/feedback/tap.tres")


## Returns true if haptics are switched on in the feature configuration
static func is_enabled() -> bool:
	var features := _get_autoload(&"VRFeatures")
	if not features:
		return true
	return features.is_enabled(&"haptics")


## Rumble [param controller] with [param magnitude] (0..1) for
## [param duration_ms] milliseconds. Events with the same [param key] on the
## same controller replace each other.
static func pulse(
		controller : XRController3D,
		magnitude : float = 0.5,
		duration_ms : int = 30,
		key : StringName = &"haptics_pulse") -> void:
	var event := XRToolsRumbleEvent.new()
	event.magnitude = clampf(magnitude, 0.0, 1.0)
	event.duration_ms = maxi(duration_ms, 10)
	event.active_during_pause = true
	play(controller, event, key)


## Rumble [param controller] with a prepared [XRToolsRumbleEvent]
static func play(
		controller : XRController3D,
		event : XRToolsRumbleEvent,
		key : StringName = &"haptics_event") -> void:
	if not is_instance_valid(controller) or not event or not is_enabled():
		return
	var manager := _get_autoload(&"XRToolsRumbleManager")
	if not manager:
		return
	manager.add(key, event, [controller])


## Short tap on [param controller] (the shipped [code]tap.tres[/code] preset)
static func tap(controller : XRController3D) -> void:
	play(controller, TAP_EVENT, &"haptics_tap")


# Find an autoload without a compile-time dependency on it
static func _get_autoload(autoload_name : StringName) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return null
	return tree.root.get_node_or_null(NodePath(autoload_name))
