extends RigidBody3D


@export var movement_speed: float = 4.0
@export var movement_force: float = 100.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detector: Area3D = $YeeYeeAssHaircutDetector


# --- Logics ---

## Stop navigation
func _stop_navigation() -> void:
	self.nav_agent.target_position = self.global_position


## Get franklin. Returns null if none are found within detector.
func _get_franklin() -> RigidBody3D:

	var bodies := self.detector.get_overlapping_bodies()
	if not bodies:
		self._stop_navigation()
		return null

	return bodies[0]


## Apply torque to look at given direction
func _look_direction(desired_global_dir: Vector3) -> void:
	self.rotate_y(
		self.global_basis.z.signed_angle_to(
			desired_global_dir, self.global_basis.y
		)
	)


## Attempt navigating to target position. Returns false if failed to do so
func _try_navigate() -> bool:

	# Do not query when the map has never synchronized and is empty.
	if not NavigationServer3D.map_get_iteration_id(self.nav_agent.get_navigation_map()):
		return false

	if self.nav_agent.is_navigation_finished():
		return false

	if not self.nav_agent.is_target_reachable():
		self._stop_navigation()

	var next_path: Vector3 = self.nav_agent.get_next_path_position()
	var new_vel: Vector3 = self.global_position.direction_to(next_path) * movement_speed

	if self.nav_agent.avoidance_enabled:
		self.nav_agent.velocity = new_vel
	else:
		# if not enabled no need for safe vel, use desired velocity directly
		self._on_velocity_computed(new_vel)

	return true


# --- Drivers ---

func _on_velocity_computed(safe_velocity: Vector3):

	# apply force to kill desired vs actual velocity difference.
	self.apply_central_force(
		(safe_velocity - self.linear_velocity).limit_length() * self.movement_force
	)


func _ready() -> void:
	self.nav_agent.velocity_computed.connect(Callable(_on_velocity_computed))


func _physics_process(delta):

	# try updating path
	var franklin := self._get_franklin()
	if franklin:
		self.nav_agent.target_position = franklin.global_position
		self._look_direction(self.global_position.direction_to(franklin.global_position))

	self._try_navigate()
