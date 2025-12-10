class_name BoxPickingPlayer extends RigidBody2D
## Player scene


# --- References ---

var box: RigidBody2D = null


# --- Logics ---

## movement processor
func movement():
	var horizontal: float = Input.get_action_strength("right") - Input.get_action_strength("left")
	var vertical: float = -500.0 if Input.is_action_just_pressed("jump") else 0.0

	# movement
	if horizontal or vertical:
		self.apply_impulse(Vector2(horizontal * 8.0, vertical))


## box releasing processor
func release_box():
	if not Input.is_action_just_pressed("release") or not self.box:
		return

	# get global pos
	var global_pos := self.box.global_position

	# reparent
	self.remove_child(self.box)
	get_tree().current_scene.add_child(self.box)

	# reset back using global pos
	self.box.position = global_pos

	# unfreeze and apply throwing impulse with player speed added
	self.box.freeze = false
	self.box.apply_impulse(self.linear_velocity + Vector2(0.0, -500.0))

	# clear ref
	self.box = null


## add box to player
func add_box(box: RigidBody2D):
	self.box = box

	# since this is in contact solver, most calls should be deferred


	# reparent bu
	box.get_parent().remove_child(box)
	self.add_child.call_deferred(box)

	# freeze & kill velocity so no gravity works
	box.freeze = true

	# set position also call deferred for safety
	# we're using normalized vector to eliminate distance variance linear to collision penetration.
	box.set_position.call_deferred((box.position - self.position).normalized() * 30.0)


# --- Driver

func _process(delta: float) -> void:
	self.movement()
	self.release_box()


func _on_body_entered(body: Node) -> void:
	# just doing dumb check here, use group id or something else in real code.
	# if already holding box also ignore
	if self.box != null or body is not RigidBody2D:
		return

	# check if box is above player
	if body.global_position.y < self.global_position.y:
		print("Adding box to player")
		self.add_box(body)
