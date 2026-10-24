class_name PassthroughController
extends Node


## Passthrough Controller
##
## Switches mixed-reality passthrough (Quest) on and off at runtime. When
## enabled it asks the XR interface for the alpha-blend environment blend
## mode (falling back to [method XRInterface.start_passthrough]), makes the
## viewport background transparent and switches the zone's
## [WorldEnvironment] to a clear-colour background so the sky does not cover
## the camera feed. Disabling restores everything.
##
## Without an XR interface (desktop, headless) enabling is a no-op that logs
## a warning. The project setting [code]xr/openxr/environment_blend_mode[/code]
## stays opaque; this node only switches at runtime.
##
## Driven by the [code]passthrough[/code] feature through [PlayerRig].


## Emitted when passthrough actually starts or stops
signal passthrough_changed(active : bool)


## Requested passthrough state
@export var enabled : bool = false: set = set_enabled


## True while passthrough is running
var active : bool = false

# Values restored when passthrough stops
var _interface : XRInterface
var _previous_blend_mode : int = XRInterface.XR_ENV_BLEND_MODE_OPAQUE
var _used_legacy_passthrough : bool = false
var _environment_node : WorldEnvironment
var _original_environment : Environment


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Retry when the XR session (re)starts, the interface may not have been
	# ready when the zone loaded.
	var staging := XRTools.find_xr_ancestor(self, "*", "XRToolsStaging")
	if staging and staging.has_signal("xr_started"):
		staging.xr_started.connect(_update)
	_update()


func _exit_tree() -> void:
	_stop()


## Set the requested passthrough state
func set_enabled(p_enabled : bool) -> void:
	enabled = p_enabled
	if is_inside_tree():
		_update()


## Returns true if the current XR interface can show passthrough
static func is_supported() -> bool:
	var xr := XRServer.primary_interface
	if not xr or not xr.is_initialized():
		return false
	return xr.get_supported_environment_blend_modes().has(
			XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND) or xr.is_passthrough_supported()


# Start or stop passthrough to match the requested state
func _update() -> void:
	if enabled and not active:
		_start()
	elif not enabled and active:
		_stop()


func _start() -> void:
	var xr := XRServer.primary_interface
	if not xr or not xr.is_initialized():
		push_warning("PassthroughController: no active XR interface, passthrough unavailable")
		return

	if xr.get_supported_environment_blend_modes().has(XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND):
		_previous_blend_mode = xr.environment_blend_mode
		xr.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
		_used_legacy_passthrough = false
	elif xr.is_passthrough_supported() and xr.start_passthrough():
		_used_legacy_passthrough = true
	else:
		push_warning("PassthroughController: XR interface does not support passthrough")
		return

	_interface = xr
	get_viewport().transparent_bg = true
	_set_clear_background(true)
	active = true
	passthrough_changed.emit(true)


func _stop() -> void:
	if not active:
		return

	if is_instance_valid(_interface):
		if _used_legacy_passthrough:
			_interface.stop_passthrough()
		else:
			_interface.environment_blend_mode = _previous_blend_mode
	_interface = null

	if is_inside_tree():
		get_viewport().transparent_bg = false
	_set_clear_background(false)
	active = false
	passthrough_changed.emit(false)


# Swap the zone environment for a transparent-background copy (or back)
func _set_clear_background(p_clear : bool) -> void:
	if p_clear:
		_environment_node = _find_world_environment()
		if not _environment_node or not _environment_node.environment:
			return
		_original_environment = _environment_node.environment
		var env := _original_environment.duplicate() as Environment
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.0, 0.0, 0.0, 0.0)
		_environment_node.environment = env
	elif is_instance_valid(_environment_node) and _original_environment:
		_environment_node.environment = _original_environment
		_environment_node = null
		_original_environment = null


# Find the WorldEnvironment of the scene this node lives in
func _find_world_environment() -> WorldEnvironment:
	var scene := XRTools.find_xr_ancestor(self, "*", "XRToolsSceneBase")
	if not scene:
		scene = get_tree().current_scene
	if not scene:
		return null
	var found := scene.find_children("*", "WorldEnvironment", true, false)
	return found[0] as WorldEnvironment if found.size() > 0 else null
