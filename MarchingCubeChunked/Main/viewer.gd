extends Node3D
## Main scene implementing marching cube 'volume' updates


# --- Exports ---

## Minimum distance for terrain update to trigger
@export var min_point_distance_for_update: float = 0.2


# --- Attributes ---

@onready var _raycast_manager := RaycastManager.create_instance(
	get_viewport(),
	get_world_3d(),
	2,
)

@onready var _pointer: MeshInstance3D = $MouseHitPoint
@onready var _manager: ChunkManager = $ChunkManager

@onready var _gen_time_label: Label = %GenTimeLabel

@onready var _thread_spinbox: SpinBox = %ThreadSpinbox
@onready var _seed_line_edit: LineEdit = %SeedLineEdit
@onready var _method_option_btn: OptionButton = %MethodOptionButton

@onready var _min_point_dist_sq: float = self.min_point_distance_for_update ** 2

@onready var _free_cam: FreeCam = $FreeCam

var _is_mouse_in_window: bool

var _last_pointer_pos: Vector3 = Vector3.ONE * -100000


# --- Methods ---

## Change volume from marching cube.
## TODO: make this darn thing multi threaded, gpu submit cost is too much
func adjust_volume(chunk: MarchingCube, pos: Vector3, radius: float, base_amount: float):

	var width: int = chunk.width
	var verts_per_edge: int = width + 1

	#print("Subtracting requested from %s" % pos)

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

	const idx_range: PackedFloat32Array = [-1, 0, 1]

	# check effect in 3x3 chunk range
	var points: Array[Vector3] = []

	for x in idx_range:
		for y in idx_range:
			for z in idx_range:
				points.append(
					Vector3(
						center.x + x * radius,
						center.y + y * radius,
						center.z + z * radius,
					)
				)

	var visited_chunks: Dictionary = {}

	for point: Vector3 in points:
		var chunk := self._manager.get_chunk(point)

		# check if nonexistence chunk or already visited chunk
		if chunk == null or chunk.get_instance_id() in visited_chunks:
			continue

		# else add to visited
		visited_chunks[chunk.get_instance_id()] = null

		self.adjust_volume(chunk, center, radius, amount)
		self._manager.update_chunk(chunk)


## Update _pointer position to mouse's position
func _update_pointer_position() -> void:
	if not _is_mouse_in_window:
		return

	var result := self._raycast_manager.raycast()
	if result:
		_pointer.show()
		_pointer.position = result["position"]
	else:
		_pointer.hide()


## Update terrain if there's valid input & condition allows
func _update_terrain() -> void:

	# check for volume action. If no visible cursor then no job.
	if not _pointer.visible:
		return

	# get _pointer position and measure distance
	var pos: Vector3 = _pointer.position

	# if distance isn't sufficient return to prevent triggering insane amount of updates
	if _last_pointer_pos.distance_squared_to(pos) < self._min_point_dist_sq:
		return

	if Input.is_action_pressed("add_volume"):
		self._last_pointer_pos = pos
		self._update_affected_chunks(pos, 0.2, -1)

	elif Input.is_action_pressed("subtract_volume"):
		self._last_pointer_pos = pos
		self._update_affected_chunks(pos, 0.2, 1)

	# reset _pointer pos to valhalla
	self._last_pointer_pos = Vector3.ONE * -100000


func _get_seed() -> int:
	var seed_: int = 0

	# if seed was set use that value, otherwise set new one & update input field
	if self._seed_line_edit.text and self._seed_line_edit.text.is_valid_int():
		seed_ = int(self._seed_line_edit.text)
	else:
		seed_ = randi()
		self._seed_line_edit.text = str(seed_)

	return seed_


func _get_method() -> StringName:
	return self._method_option_btn.get_item_text(self._method_option_btn.selected)


# --- Handlers ---

func _ready() -> void:
	self._thread_spinbox.value = self._manager.max_threads

	# popuplate option button & select last
	for method: StringName in DensityFuncs.FUNC_TYPE:
		self._method_option_btn.add_item(method)

	self._method_option_btn.select(len(DensityFuncs.FUNC_TYPE) - 1)

	# generate chunk grids & connect signal, then trigger start
	self._manager.generation_done.connect(self._on_manager_generation_done)
	self._manager.generate_chunk(self._get_seed(), self._get_method())
	self._on_regen_button_pressed.call_deferred()

	# compile pattern ahead
	#self._digit_pattern.compile("[0-9]*")

	self._free_cam.position = Vector3(0, 17, 15)
	self._free_cam.look_pos(Vector3(0, -1, 0))


func _on_regen_button_pressed() -> void:
	var threads: int = int(self._thread_spinbox.value)

	if self._manager.max_threads != threads:
		self._manager.set_thread_count(threads)

	self._manager.regenerate_all(self._get_seed(), self._get_method())


func _on_manager_generation_done(elapsed_sec: float) -> void:
	self._gen_time_label.text = "Gen. Time : %.2f s" % elapsed_sec


func _physics_process(_delta: float) -> void:
	self._update_pointer_position()
	self._update_terrain()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_MOUSE_ENTER:
			self._is_mouse_in_window = true

		NOTIFICATION_WM_MOUSE_EXIT:
			self._is_mouse_in_window = false


func _on_seed_line_edit_text_submitted(_new_text: String) -> void:
	self._seed_line_edit.release_focus()
