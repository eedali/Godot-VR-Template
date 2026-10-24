extends CenterContainer


## Start Menu UI
##
## The 2D menu shown on the start scene screen. It switches between the main
## menu, new-game, load-game and options panes and starts the game through
## the [GameState] autoload.


## Panes of the start menu
enum Pane {
	MAIN_MENU,
	NEW_GAME,
	LOAD_GAME,
	OPTIONS,
}


## Names of the save games shown in the load-game pane
var save_list : Array[String] = []

@onready var _save_list_node : ItemList = $LoadGame/SaveList


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_pane(Pane.MAIN_MENU)

	# Get our list of save games
	if PersistentWorld.instance:
		save_list = PersistentWorld.instance.list_saves()

		_save_list_node.clear()
		for entry in save_list:
			_save_list_node.add_item(entry)

	$MainMenu/LoadGameBtn.disabled = save_list.is_empty()


# Show only the requested pane
func _set_pane(p_pane : Pane) -> void:
	$MainMenu.visible = p_pane == Pane.MAIN_MENU
	$NewGame.visible = p_pane == Pane.NEW_GAME
	$LoadGame.visible = p_pane == Pane.LOAD_GAME
	$Options.visible = p_pane == Pane.OPTIONS


# Main menu

func _on_new_game_btn_pressed() -> void:
	_set_pane(Pane.NEW_GAME)


func _on_load_game_btn_pressed() -> void:
	_set_pane(Pane.LOAD_GAME)


func _on_options_btn_pressed() -> void:
	_set_pane(Pane.OPTIONS)


func _on_exit_btn_pressed() -> void:
	get_tree().quit()


# New game

func _on_easy_btn_pressed() -> void:
	GameState.new_game(GameState.GameDifficulty.GAME_EASY)


func _on_normal_btn_pressed() -> void:
	GameState.new_game(GameState.GameDifficulty.GAME_NORMAL)


func _on_hard_btn_pressed() -> void:
	GameState.new_game(GameState.GameDifficulty.GAME_HARD)


func _on_back_btn_pressed() -> void:
	_set_pane(Pane.MAIN_MENU)


# Load game

func _on_start_button_pressed() -> void:
	var selected_items := _save_list_node.get_selected_items()
	if selected_items.size() != 1:
		return

	var selected_item : int = selected_items[0]
	if selected_item < 0 or selected_item >= save_list.size():
		return

	GameState.load_game(save_list[selected_item])
