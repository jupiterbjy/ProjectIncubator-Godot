extends Control
## Main scene script


# --- Drivers ---

func _on_show_image_viewer_button_pressed() -> void:
	var instance := ImageViewerPopup.create_instance(self.get_tree().current_scene)
	instance.position = self.get_rect().get_center() - instance.get_rect().size * 0.5


func _on_show_ad_button_pressed() -> void:
	var instance := SubViewportPopup.create_instance(self.get_tree().current_scene)
	instance.position = self.get_rect().get_center() - instance.get_rect().size * 0.5
