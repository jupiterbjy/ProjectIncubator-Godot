extends Node3D

@onready var raycast_manager := RaycastManager.create_instance(
	get_viewport(),
	get_world_3d(),
	2,
)

@onready var pointer: MeshInstance3D = $MouseHitPoint
@onready var manager: ChunkManager = $ChunkManager


## Change volume from marching cube.
## TODO: make this darn thing multi threaded, gpu submit cost is too much
func adjust_volume(chunk: MarchingCube, pos: Vector3, radius: float, base_amount: float):
	var width: int = chunk.width
	var verts_per_edge: int = width + 1

	print("Subtracting requested from %s" % pos)

	for x in range(verts_per_edge):
		for y in range(verts_per_edge):
			for z in range(verts_per_edge):
				var flat_idx = x * (verts_per_edge ** 2) + y * verts_per_edge + z

				var target_pos := (Vector3(x, y, z) / width) + chunk.pos
				var distance: float = pos.distance_to(target_pos)

				if distance < radius:
					chunk._heights[flat_idx] = clampf(
						chunk._heights[flat_idx] + base_amount * (radius - distance) / radius,
						-1, 1
					)


## Returns array of affected cubes
func _update_affected_chunks(center: Vector3, radius: float, amount: float):
	var points: Array[Vector3] = [
		center + Vector3(radius, radius, radius),
		center + Vector3(radius, radius, -radius),
		center + Vector3(radius, -radius, radius),
		center + Vector3(radius, -radius, -radius),
		center + Vector3(-radius, radius, radius),
		center + Vector3(-radius, radius, -radius),
		center + Vector3(-radius, -radius, radius),
		center + Vector3(-radius, -radius, -radius),
	]

	var visited_chunks: Dictionary = {}

	for point: Vector3 in points:
		var chunk := self.manager.get_chunk(point)

		# check if nonexistence chunk or already visited chunk
		if chunk == null or chunk.get_instance_id() in visited_chunks:
			continue

		# else add to visited
		visited_chunks[chunk.get_instance_id()] = null

		self.adjust_volume(chunk, center, radius, amount)
		self.manager.update_chunk(chunk)



# --- Raycast ---

var mouse_within_window: bool
var mouse_on_chunk: bool


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_MOUSE_ENTER:
			self.mouse_within_window = true

		NOTIFICATION_WM_MOUSE_EXIT:
			self.mouse_within_window = false


func _physics_process(delta: float) -> void:

	if not mouse_within_window:
		return

	var result := raycast_manager.raycast()
	if result:
		pointer.show()
		pointer.position = result["position"]
	else:
		pointer.hide()


var last_pointer_pos: Vector3 = Vector3.ONE * -100000


# --- Terrain update ---

@export var min_point_distance_for_update: float = 0.2
@onready var _min_point_dist_sq: float = self.min_point_distance_for_update ** 2

var _cooltime: float = 0.0


func _process(delta: float) -> void:
	self._cooltime += delta

	# check for volume action. If no visible cursor then no job.
	if not pointer.visible:
		return

	# get pointer position and measure distance
	var pos: Vector3 = pointer.position

	# if distance isn't sufficient return
	if last_pointer_pos.distance_squared_to(pos) < self._min_point_dist_sq:
		return

	if Input.is_action_pressed("AddVolume"):
		# update last pos
		self.last_pointer_pos = pos
		self._update_affected_chunks(pos, 0.2, -1)

	elif Input.is_action_pressed("RemoveVolume"):
		# update last pos
		self.last_pointer_pos = pos
		self._update_affected_chunks(pos, 0.2, 1)

	# reset pointer pos to valhalla
	self.last_pointer_pos = Vector3.ONE * -100000


# --- UI ---

func _on_regen_button_pressed() -> void:
	var threads: int = int(%ThreadSpinbox.value)

	if self.manager.max_threads != threads:
		self.manager.set_thread_count(threads)

	var _seed: int = 0

	if %SeedLineEdit.text:
		_seed = int(%SeedLineEdit.text)
	else:
		_seed = randi()
		%SeedLineEdit.text = str(_seed)

	self.manager.regenerate_chunk(_seed)


func _on_manager_generation_done(elapsed_sec: float) -> void:
	%GenTimeLabel.text = "Gen. Time : %.2f s" % elapsed_sec


func _ready() -> void:
	%ThreadSpinbox.value = self.manager.max_threads
	self._on_regen_button_pressed()
	self.manager.generation_done.connect(self._on_manager_generation_done)
