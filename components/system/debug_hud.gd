class_name DebugHUD
extends Node3D


## Debug HUD
##
## A small head-locked panel (child of the [XRCamera3D]) showing FPS, frame
## time, draw calls and battery, for Quest frame-budget work. The panel
## refreshes at 4 Hz through a throttled [XRToolsViewport2DIn3D], so it costs
## almost nothing while visible and nothing while disabled.
##
## Never shown in release builds: the node frees itself when
## [method OS.is_debug_build] is false. Driven by the [code]debug_hud[/code]
## feature through [PlayerRig].


## If true the HUD is shown
@export var enabled : bool = false: set = set_enabled

@onready var _viewport : Node3D = $Viewport


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	_update()


## Show or hide the HUD
func set_enabled(p_enabled : bool) -> void:
	enabled = p_enabled
	if is_node_ready():
		_update()


func _update() -> void:
	visible = enabled
	_viewport.update_mode = XRToolsViewport2DIn3D.UpdateMode.UPDATE_THROTTLED if enabled \
			else XRToolsViewport2DIn3D.UpdateMode.UPDATE_ONCE
	var panel : Node = _viewport.get_scene_instance()
	if panel and panel.has_method("set_running"):
		panel.set_running(enabled)
