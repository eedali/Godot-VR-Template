class_name DesktopFallback
extends Node3D


## Desktop Fallback
##
## Groups the XR Tools desktop-support nodes so a [PlayerRig] can add
## keyboard and mouse controls in one call when no headset is available:
## mouse capture (Esc releases), WASD / arrow movement, mouse turning, jump,
## crouch, sprint, a camera pointer (left mouse button) and controller hiders.
##
## The movement providers are children of this node (they only need an
## [XROrigin3D] ancestor). The pointer must live under the [XRCamera3D] and
## the hiders under the controllers, so they are created there in
## [method _ready] and removed again when this node leaves the tree.
##
## Input actions are registered at runtime if the project does not define
## them, so a game can remap them in Project Settings > Input Map.
##
## Instanced by [PlayerRig] for the [code]desktop_fallback[/code] feature
## when [member XRServer.primary_interface] is null.


## Default key bindings registered when an action is missing
const KEY_ACTIONS : Dictionary = {
	&"desktop_forward": [KEY_W, KEY_UP],
	&"desktop_back": [KEY_S, KEY_DOWN],
	&"desktop_left": [KEY_A, KEY_LEFT],
	&"desktop_right": [KEY_D, KEY_RIGHT],
	&"desktop_jump": [KEY_SPACE],
	&"desktop_crouch": [KEY_C, KEY_CTRL],
	&"desktop_sprint": [KEY_SHIFT],
}

## Mouse button used by the desktop pointer
const CLICK_ACTION := &"desktop_click"


## Pointer created under the camera
@export var pointer_scene : PackedScene = \
		preload("res://addons/godot-xr-tools/desktop-support/function_desktop_pointer.tscn")

## Hider created under each controller (hides the hands while in desktop mode)
@export var controller_hider_scene : PackedScene = \
		preload("res://addons/godot-xr-tools/desktop-support/controller_hider.tscn")

# Nodes this fallback created outside its own subtree
var _added : Array[Node] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	register_input_actions()

	var camera := XRHelpers.get_xr_camera(self)
	if camera and pointer_scene:
		var pointer := pointer_scene.instantiate()
		pointer.set("active_button_action", String(CLICK_ACTION))
		_add_outside(camera, pointer)

	if controller_hider_scene:
		for controller in [XRHelpers.get_left_controller(self), XRHelpers.get_right_controller(self)]:
			if controller:
				_add_outside(controller, controller_hider_scene.instantiate())


func _exit_tree() -> void:
	for node in _added:
		if is_instance_valid(node):
			node.queue_free()
	_added.clear()


## Add the desktop input actions to the [InputMap] unless they exist
static func register_input_actions() -> void:
	for action : StringName in KEY_ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key : Key in KEY_ACTIONS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

	if not InputMap.has_action(CLICK_ACTION):
		InputMap.add_action(CLICK_ACTION)
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(CLICK_ACTION, click)


# Add a node under a parent outside this subtree and remember it
func _add_outside(parent : Node, node : Node) -> void:
	parent.add_child(node)
	node.owner = parent.owner if parent.owner else parent
	_added.append(node)
