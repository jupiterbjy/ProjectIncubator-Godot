extends Node
## Fullscreen toggle autoload. yup that's all.


var _DEFAULT_SCREEN_MODE = null


func _unhandled_input(event: InputEvent) -> void:

	if event.is_action_released("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(self._DEFAULT_SCREEN_MODE)

		else:
			self._DEFAULT_SCREEN_MODE = DisplayServer.window_get_mode()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
