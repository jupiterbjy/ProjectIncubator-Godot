extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var z: float = Input.get_axis(&"forward", &"backward")
	var x: float = Input.get_axis(&"left", &"right")

	self.apply_central_force(Vector3(x, 0.0, z) * 4.0)
