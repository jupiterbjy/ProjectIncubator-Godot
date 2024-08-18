extends MeshInstance2D
## Spawns boxes


@export var box_scene: PackedScene


func _on_timer_timeout() -> void:
	# spawn box in air

	var instance: RigidBody2D = self.box_scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.position = self.position
