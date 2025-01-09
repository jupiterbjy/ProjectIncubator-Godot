class_name HitReport extends Label
## Auto destroying UI element for contact message display


# --- References ---

## Scene ref for easier instancing
const _SCENE: PackedScene = preload("uid://cinup2qupst7e")


# --- Utilities ---

## Create new scene instance
static func create_instance(message: String) -> HitReport:
	var instance: HitReport = _SCENE.instantiate()
	instance.text = message

	return instance


# --- Drivers ---

func _on_timer_timeout() -> void:
	var tween := self.create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1)
	tween.tween_callback(self.queue_free)
