extends Label


func _process(delta: float) -> void:
	self.text = "AVG FPS: %s\n" % [
		Engine.get_frames_per_second()
	]
