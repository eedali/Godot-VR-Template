extends PanelContainer


## Zone Wrist UI
##
## Menu on the left wrist while playing: save, quit to the start menu, and
## jump to the showcase zone (handy while testing a game built from the
## template; remove the button for release).


## Zone loaded by the "Showcase" button
@export var showcase_zone : PersistentZoneInfo

## Spawn marker used in the showcase zone
@export var showcase_spawn : String = "FromAnywhere"


func _on_save_button_pressed() -> void:
	GameState.auto_save_game()


func _on_quit_button_pressed() -> void:
	GameState.quit_game()


func _on_showcase_button_pressed() -> void:
	var zone := GameState.current_zone
	if not is_instance_valid(zone) or not showcase_zone:
		return
	if zone.zone_info and zone.zone_info.zone_id == showcase_zone.zone_id:
		return
	zone.load_scene(showcase_zone.instance_scene, showcase_spawn)
