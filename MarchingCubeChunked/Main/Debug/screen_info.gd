extends Label


func _physics_process(_delta: float) -> void:
	self.text = "Resolution: %s
	Framerate : %s" % [DisplayServer.window_get_size(), Engine.get_frames_per_second()]
