extends Node3D

@onready var map: GroundMap = $GroundMap
@onready var cam_holder: Node3D = $CamHolder

@onready var x_spin: SpinBox = %XSpinBox
@onready var y_spin: SpinBox = %YSpinBox


func _ready() -> void:
	%SeedLabel.text = str(self.map.get_seed())


func _on_randomize_button_pressed() -> void:
	self.map.set_random_seed()
	self.cam_holder.position = self.map.recreate_map()
	%SeedLabel.text = str(self.map.get_seed())


func _on_x_spin_box_value_changed(value: float) -> void:
	# TODO: add input check
	self.map.cols = value
	self.cam_holder.position = self.map.recreate_map()


func _on_y_spin_box_value_changed(value: float) -> void:
	self.map.rows = value
	self.cam_holder.position = self.map.recreate_map()


func _on_seed_label_text_submitted(new_text: String) -> void:
	if new_text.is_valid_int():
		self.map.set_seed(new_text.to_int())
		self.cam_holder.position = self.map.recreate_map()
	else:
		%SeedLabel.clear()


func _on_play_button_pressed() -> void:
	pass # Replace with function body.
