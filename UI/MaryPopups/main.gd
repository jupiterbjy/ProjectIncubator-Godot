extends Control
## Main scene script


# --- Drivers ---

func _on_show_image_viewer_button_pressed() -> void:
	ImageViewerPopup.create_instance(self.get_tree().current_scene)


func _on_show_ad_button_pressed() -> void:
	SubViewportPopup.create_instance(self.get_tree().current_scene)
