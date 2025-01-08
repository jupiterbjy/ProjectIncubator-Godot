class_name VerticalFitImageButton extends TextureRect
## TextureRect acting as if it's a button
## Because it has experiemental expand_mode flags.


# --- Signals ---

signal selected(self_ref: VerticalFitImageButton)


# --- References ---

## Currently set image's file name
var file_name: String

# usually I'd just use this and instanciate scene instead of new but this is simple enough
# so we'll just do all config in create_instance call, even signals too.
# const _SCENE: PackedScene = preload("uid://cvqh8mkxlyrsb")


# --- Utilities ---

## Named scene constructor
static func create_instance(img_path: String) -> VerticalFitImageButton:
	var instance := VerticalFitImageButton.new()

	instance.texture = ResourceLoader.load(img_path)
	instance.file_name = img_path.get_file()

	instance.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	instance.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	instance.size_flags_vertical = Control.SIZE_EXPAND_FILL

	instance.gui_input.connect(instance._on_gui_input)

	return instance


# --- Drivers ---

func _on_gui_input(event: InputEvent) -> void:
	# Since we aint using button we get all event. Fail fast on all irrelevants.
	if (
		event is not InputEventMouseButton
		or (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT
		or (event as InputEventMouseButton).is_pressed()
	):
		return

	# else signal to notify that I'm the one who rocks
	self.selected.emit(self)
