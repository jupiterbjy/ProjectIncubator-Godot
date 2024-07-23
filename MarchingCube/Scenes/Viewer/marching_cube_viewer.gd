extends Node3D
## Marching Cube Viewer


@onready var marching_cube: MarchingCube = $MarchingCube

@onready var pos_label: Label = %PosLabel
@onready var pause_button: Button = %PauseButton

@onready var turntable_cam: Node3D = $TurntableCam
@onready var turntable_light: Node3D = $TurntableLight


var _rotation_speed: float = 0.5
var _chunk_pos: Vector3 = Vector3(0, 0, 0)
var _pause: bool = false
var _rotation: bool = true


func _process(delta: float) -> void:

	if not _pause:
		# change pos and update
		self._chunk_pos += Vector3(delta * 0.2, 0.0, 0.0)
		self.marching_cube.set_chunk_pos(self._chunk_pos)
		self.pos_label.text = "Pos %.2v" % self._chunk_pos

	if _rotation:
		# rotate cam and light.
		# originally cube was turning one, but to prevent global->local normal calculation in
		# shader I instead put camera in turntable instead. Relativity, son!
		self.turntable_cam.rotate_y(delta * 0.5 * _rotation_speed)
		self.turntable_light.rotate_y(-delta * 1.5 * _rotation_speed)


# --- Driver ---

func _ready() -> void:
	# populate option button
	var option_btn: OptionButton = %OptionButton
	option_btn.clear()
	
	for _name in self.marching_cube.density_func.FUNC_TYPE:
		option_btn.add_item(_name)
	
	# init cube
	self.marching_cube.regenerate_all()

	# set initial density option & noise frequency selection just in case
	self.marching_cube.density_type = option_btn.selected
	self.marching_cube.set_noise_frequency(%FreqSpinBox.value)


# --- Signals ---

func _on_w_spin_box_value_changed(value: float) -> void:
	self.marching_cube.set_width(value)


func _on_threshold_spin_box_value_changed(value: float) -> void:
	self.marching_cube.set_threshold(value)


func _on_randomize_button_pressed() -> void:
	var val := randi()
	%SeedLabel.text = str(val)

	self.marching_cube.set_noise_seed(val)


func _on_pause_button_toggled(toggled_on: bool) -> void:
	self._pause = toggled_on


func _on_smoothness_spin_box_value_changed(value: float) -> void:
	self.marching_cube.smoothness = value
	self.marching_cube.regenerate_mesh()


func _on_vert_show_button_toggled(toggled_on: bool) -> void:
	# hidden access but it's for debuging so let it happen
	self.marching_cube._marker_root.visible = toggled_on


func _on_flat_shade_button_toggled(toggled_on: bool) -> void:
	self.marching_cube.flat_shading = toggled_on
	self.marching_cube.regenerate_mesh()


func _on_rotation_button_toggled(toggled_on: bool) -> void:
	self._rotation = toggled_on


func _on_blending_spin_box_value_changed(value: float) -> void:
	self.marching_cube.set_blending_factor(value)


func _on_option_button_item_selected(index: int) -> void:
	self.marching_cube.density_type = index
	self.marching_cube.regenerate_mesh()


func _on_freq_spin_box_value_changed(value: float) -> void:
	self.marching_cube.set_noise_frequency(value)
