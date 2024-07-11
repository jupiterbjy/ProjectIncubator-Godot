extends SpinBox
## Script to allow scroll wheel on spinbox without clicking


func _on_mouse_entered() -> void:
	self.get_line_edit().grab_focus.call_deferred()


func _on_mouse_exited() -> void:
	self.get_line_edit().release_focus()
