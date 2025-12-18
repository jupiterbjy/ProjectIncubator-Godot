@tool
class_name PopupBase extends Panel
## Base class for ingame popups.
## Inherit this scene & Script, then create contents inside the `ZeContentGoesHere`.


# --- Exports ---

## Title of popup window. Applies immediately in editor viewport.
@export var title: String:
	set(val):
		# set new title upon change
		title = val
		self._delayed_title_set.call_deferred(val)


## Availability of close button, in case you prefer unclosable AD!
@export var show_close_button: bool = true:
	set(val):
		# change visibility
		show_close_button = val
		self._delayed_close_visibility_set.call_deferred(val)


# --- References ---

@onready var _title_label: Label = %TitleLabel
@onready var _close_button: TextureButton = %CloseButton

## Used for window dragging event check
var _is_dragging: bool = false

## Used for resize event check
var _is_resize_dragging: bool = false


# --- Utilities ---

## A wrapper function to delay value setting on startup til end of frame.
func _delayed_title_set(val: String) -> void:
	if self._title_label:
		self._title_label.text = val


## A wrapper function to delay value setting on startup til end of frame.
func _delayed_close_visibility_set(val: bool) -> void:
	if self._close_button:
		self._close_button.visible = val



# --- Drivers ---

## cleanup popup
func _on_close_button_pressed() -> void:
	self.queue_free()


## Move popup around till mouse is released
func _on_title_label_gui_input(event: InputEvent) -> void:

	# if left click change state and just return
	if (
		event is InputEventMouseButton and
		(event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	):
		self._is_dragging = event.is_pressed()

		# if it was press event, then change child order,
		# thus increase view order
		if self._is_dragging:
			self.get_parent().move_child(self, -1)
		return

	# if motion during click follow window
	if event is InputEventMouseMotion and self._is_dragging:
		self.position += (event as InputEventMouseMotion).relative


func _on_resize_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and self._is_resize_dragging:
		self.size += (event as InputEventMouseMotion).relative


func _on_resize_button_button_down() -> void:
	self._is_resize_dragging = true


func _on_resize_button_button_up() -> void:
	self._is_resize_dragging = false
