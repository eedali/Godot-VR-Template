extends PanelContainer


## Showcase UI panel
##
## 2D content of the showcase UI station: a button with a click counter (to
## try the laser pointer) and a text field (to try the virtual keyboard).


var _clicks : int = 0

@onready var _counter : Label = $Margin/VBox/Counter


func _on_click_button_pressed() -> void:
	_clicks += 1
	_counter.text = "Clicked %d time%s" % [_clicks, "" if _clicks == 1 else "s"]
