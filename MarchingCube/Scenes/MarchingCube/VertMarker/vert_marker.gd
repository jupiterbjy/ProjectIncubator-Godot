extends MeshInstance3D

@export var height_gradiant: Gradient


func set_height(height: float) -> void:
	var mat: StandardMaterial3D = self.get_active_material(0)

	# since height is -1~1 we offset it to 0~1
	var color: Color = self.height_gradiant.sample((height + 1) / 2.0)

	# set material color
	mat.albedo_color = color
	mat.emission = color
