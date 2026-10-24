extends SceneTree


## Headless smoke test
##
## Loads every .tscn / .tres / .gd under the scanned folders, instantiates
## every PackedScene (without adding it to the tree, so no _ready runs) and
## re-parses every GDScript. Any failure is reported and the process exits
## with code 1.
##
## Run with:
##   bash tools/godot.sh --headless --path . --script res://tools/smoke_test.gd


## Folders scanned recursively (addons are upstream and intentionally skipped)
const SCAN_DIRS : Array[String] = [
	"res://game",
	"res://components",
	"res://config",
]

## Extra single files that must always load
const EXTRA_FILES : Array[String] = [
	"res://project.godot",
	"res://openxr_action_map.tres",
	"res://default_env.tres",
]

var _failures : Array[String] = []
var _checked : int = 0


func _init() -> void:
	# Defer so the SceneTree is fully constructed before we load resources
	_run.call_deferred()


func _run() -> void:
	for dir in SCAN_DIRS:
		_scan(dir)
	for file in EXTRA_FILES:
		if file.ends_with(".godot"):
			if not FileAccess.file_exists(file):
				_failures.append(file + " (missing)")
			continue
		_check(file)

	print("smoke_test: %d files checked, %d failure(s)" % [_checked, _failures.size()])
	for failure in _failures:
		printerr("FAIL: " + failure)

	quit(1 if _failures.size() > 0 else 0)


func _scan(path : String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		# A scanned folder may not exist yet (e.g. res://config before phase 2)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := path.path_join(name)
		if dir.current_is_dir():
			if not name.begins_with("."):
				_scan(full)
		elif name.ends_with(".tscn") or name.ends_with(".tres") or name.ends_with(".gd"):
			_check(full)
		name = dir.get_next()
	dir.list_dir_end()


func _check(path : String) -> void:
	_checked += 1
	if not ResourceLoader.exists(path):
		_failures.append(path + " (ResourceLoader.exists == false)")
		return

	# Every ext_resource the file references must exist (Godot otherwise loads
	# the file with a missing dependency and only prints an error).
	for dep in ResourceLoader.get_dependencies(path):
		if not _dependency_exists(dep):
			_failures.append(path + " (missing dependency: %s)" % dep)

	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	if res == null:
		_failures.append(path + " (load returned null)")
		return

	if res is PackedScene:
		var scene := res as PackedScene
		if not scene.can_instantiate():
			_failures.append(path + " (PackedScene.can_instantiate == false)")
			return
		var inst := scene.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
		if inst == null:
			_failures.append(path + " (instantiate returned null)")
			return
		inst.free()
	elif res is GDScript:
		var script := res as GDScript
		# A script with compile errors still loads, but cannot be instantiated.
		if not script.can_instantiate() and not script.is_abstract():
			_failures.append(path + " (script does not compile)")


## Dependency strings are "uid::type::path" (or just a path); any slice that
## starts with res:// is the path, any slice that starts with uid:// is the uid.
func _dependency_exists(dep : String) -> bool:
	var dep_path := ""
	var dep_uid := ""
	for i in dep.get_slice_count("::"):
		var part := dep.get_slice("::", i)
		if part.begins_with("res://"):
			dep_path = part
		elif part.begins_with("uid://"):
			dep_uid = part
	if dep_path != "" and ResourceLoader.exists(dep_path):
		return true
	if dep_uid != "":
		var id := ResourceUID.text_to_id(dep_uid)
		if id != ResourceUID.INVALID_ID and ResourceUID.has_id(id):
			return ResourceLoader.exists(ResourceUID.get_id_path(id))
	return false
