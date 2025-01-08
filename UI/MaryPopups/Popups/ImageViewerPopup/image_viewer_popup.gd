@tool
class_name ImageViewerPopup extends PopupBase
## Button demo that actually is just neko scribble viewer


# --- References ---

const IMG_DIR := "res://Popups/ImageViewerPopup/Images/"
static var IMG_PATHS: PackedStringArray = DirAccess.get_files_at(IMG_DIR)


## Used to display thumbnail image(while it ain't actually) buttons
@onready var _img_grid: GridContainer = %ImageGrid

## Used to display selected image
@onready var _img_texture_rect: TextureRect = %ImageTextureRect

## Used to display selected image's name
@onready var _file_name_label: Label = %FileNameLabel


## Scene ref for named scene constructor
const _SCENE: PackedScene = preload("uid://cvcx0x5t0hhe3")


# --- Utilities ---

## Instantiate scene and automatically add self as child to given parent
static func create_instance(parent: Node) -> ImageViewerPopup:
	var instance: ImageViewerPopup = _SCENE.instantiate()
	parent.add_child(instance)
	return instance


# --- Logics ---

## Loads images into right grid as buttons.
func _load_images_into_grid() -> void:

	for img_path: String in IMG_PATHS:

		# when exported there's no actual images but `.import` files,
		# so factor for it in editor run too
		if not img_path.ends_with(".import"):
			continue

		print("Adding image", img_path)
		var button := VerticalFitImageButton.create_instance(
			IMG_DIR + img_path.trim_suffix(".import")
		)

		# connect signal and add child
		button.selected.connect(self._on_selection_event)
		self._img_grid.add_child(button)


# --- Drivers ---

## Updates left pannel's displayed events
func _on_selection_event(selected_button: VerticalFitImageButton) -> void:

	self._file_name_label.text = selected_button.file_name
	self._img_texture_rect.texture = selected_button.texture


func _ready() -> void:
	self._load_images_into_grid()
