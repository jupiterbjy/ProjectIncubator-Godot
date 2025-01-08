extends Node3D


# --- Drivers ---

func _process(delta: float) -> void:
	self.rotate_y(delta)
