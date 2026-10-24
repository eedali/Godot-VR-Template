extends PanelContainer


## Debug HUD panel
##
## 2D content of the [code]DebugHUD[/code] viewport: FPS, frame and physics
## time, draw calls, physics rate and static memory. Refreshed by a [Timer]
## ([member refresh_hz] times per second), never every frame.
##
## Godot 4 has no battery API in [OS]; on Quest the battery level is shown by
## the system UI (or read through an Android plugin if a game needs it).


## Label refresh rate in Hz
@export var refresh_hz : float = 4.0

@onready var _label : Label = $Margin/Label
@onready var _timer : Timer = $Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_timer.wait_time = 1.0 / maxf(refresh_hz, 0.1)
	_timer.timeout.connect(_refresh)
	_timer.start()
	_refresh()


## Pause or resume refreshing
func set_running(p_running : bool) -> void:
	if not is_node_ready():
		return
	_timer.paused = not p_running


# Update the label text
func _refresh() -> void:
	var fps := Engine.get_frames_per_second()
	var frame_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draw_calls := RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var memory_mb := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var line1 := "FPS %d   frame %.1f ms   physics %.1f ms" % [fps, frame_ms, physics_ms]
	var line2 := "draw calls %d   physics %d Hz   memory %.0f MB" % [
			draw_calls, Engine.physics_ticks_per_second, memory_mb]
	_label.text = line1 + "\n" + line2
