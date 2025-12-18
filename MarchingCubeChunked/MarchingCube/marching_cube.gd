class_name MarchingCube extends Node3D
## Godot marching cube implementation for Cube.
## Multithreading is not implemented.


# --- Exports ---

@export_group("Generation")

## Noise generator
@export var noise: FastNoiseLite

## isovalue or threshold, deciding which value to be boundary of solid & empty
@export var threshold: float = 0.0

## Smoothness of generated mesh. 0.0 gives blocky feeling
@export_range(0.0, 1.0) var smoothness: float = 1.0


@export_group("Visual")

## Decide whether to apply flat shading or not
@export var flat_shading: bool = false

@export var gen_plaetu: bool = false


# --- Attributes ---

## Division width
static var width: int = 16

@onready var _mesh_instance: MeshInstance3D = $MeshInstance
@onready var _collision_shape: CollisionShape3D = $StaticBody3D/CollisionShape3D

## Cache verts counts per edge
@onready var _w_verts: int = self.width + 1

## Cache squared verts count for indexing
@onready var _sq_w_verts: int = self._w_verts ** 2

## Cache wireframe mesh for debugging
@onready var _debug_mesh_idle: MeshInstance3D = $DebugMeshIdle
@onready var _debug_mesh_processing: MeshInstance3D = $DebugMeshProcessing

## Just copy of self.position but is not property, so thread can use it.
## Set this externally
var pos: Vector3

var is_sampled: bool = false

## Mutex used to enable/disable red boundary to show current chunk is being generated
var generation_mutex: Mutex = Mutex.new()

## Function used for sampling
var sampler: StringName = DensityFuncs.FUNC_TYPE[0]


# --- Methods ---
# Convenient helper methods that sets parameter & regenerate mesh as needed.
# For actual in-game usage, most of is probably not needed.

## Dump all mesh, verts and regenerate from scratch.
## Since this is expensive call when:[br]
## - initializing[br]
## - width change
func regenerate_all() -> void:
	self.recreate_grid()
	self.resample_density()
	self.regenerate_mesh()


## Convenience setup func for setting threshold. Updates mesh.
## Set threshold (or iso level) only. Only shows verts that's below threshold.
## Height above 0 will be empty while belows become solid.
func set_threshold(new_threshold: float) -> void:
	self.threshold = new_threshold

	# we only need to regenerate mesh, right?
	# ...right?
	self.regenerate_mesh()
	# yeah I think it was, good job old me


## Convenient setup func for setting width.
## Regenerates entire grid from scratch.
func set_width(new_width: float, update=true) -> void:
	self.width = int(new_width)

	self._w_verts = self.width + 1
	self._sq_w_verts = self._w_verts ** 2

	if update:
		self.regenerate_all()


## Convenience function for changing blending factor.
func set_blending_factor(factor: float) -> void:
	var mat: ShaderMaterial = self._mesh_instance.get_active_material(0)
	mat.set_shader_parameter("BlendFactor", factor)


## Set noise. Does not regenerate mesh.
func resample_density() -> void:

	var sampler_func := DensityFuncs.get_sampler_func(self.sampler)

	for x in range(self._w_verts):
		var x_flat_idx: int = self._sq_w_verts * x

		for y in range(self._w_verts):
			var y_flat_idx: int = self._w_verts * y

			for z in range(self._w_verts):
				var flat_idx = x_flat_idx + y_flat_idx + z

				# we're dividing by vert width to make sure UV 1:1 match width
				var height: float = sampler_func.call(
					self.noise,
					self.pos + (Vector3(x, y, z) / self.width),
				)

				self._heights[flat_idx] = height

	self.is_sampled = true


## Convenience wrapper for setting noise seed. Regenerate noise & mesh.
func set_noise_seed(new_seed: int, update=true) -> void:
	self.noise.seed = new_seed
	self.is_sampled = false

	if update:
		self.resample_density()
		self.regenerate_mesh()


## Set noise scale
func set_noise_frequency(new_freq: float, update=true) -> void:
	self.noise.frequency = new_freq
	self.is_sampled = false

	if update:
		self.resample_density()
		self.regenerate_mesh()


## Set noise offset
func set_noise_offset(new_offset: Vector3, update=true) -> void:
	self.noise.offset = new_offset
	if update:
		self.resample_density()
		self.regenerate_mesh()


## Generate mesh vertex arr.
func regenerate_mesh() -> void:
	var vert_arr := self._generate_vertex_arr()
	self._generate_mesh(vert_arr)


## Clear mesh & collision shape
func clear_mesh() -> void:
	self._mesh_instance.mesh = null
	self._collision_shape.shape = null


## Creates new grid filled with 1.0.
func recreate_grid() -> void:

	# cache vertex count per edge & square of it for faster flat array acess
	self._w_verts = self.width + 1
	self._sq_w_verts = self._w_verts ** 2

	# clear array, resize and fill with 'air'
	self._heights.clear()
	self._heights.resize(self._w_verts ** 3)
	self._heights.fill(1.0)


# --- Height Grid ---
# NOTE: This are kept to allow fast update without regenerating whole grid

## 1-dim height array that is accessed via 3D array.
## Has size of width + 1, height + 1, width + 1.
var _heights: Array[float]


## Get height value at given coordinate
func _get_height(inner_pos: Vector3i) -> float:
	return self._heights[self._sq_w_verts * inner_pos.x + self._w_verts * inner_pos.y + inner_pos.z]


# --- Utility Function ---

## Interpolates verts' position within chunk
func _interpolate(iso_level: float, vert_a: Vector3i, vert_b: Vector3i) -> Vector3:
	var a_height: float = self._get_height(vert_a)
	var b_height: float = self._get_height(vert_b)

	# check if div by zero, if so return half
	if b_height == a_height:
		return (Vector3(vert_a) + Vector3(vert_b)) / 2.0

	# eles interpolate
	var factor: float = (iso_level - a_height) / (b_height - a_height)
	return Vector3(vert_a) + factor * Vector3(vert_b - vert_a)


## enable generating flag + safeguard to make sure one chunk is processed by one thread only
func debug_set_generating() -> void:
	self.generation_mutex.lock()
	self._debug_mesh_idle.hide()
	self._debug_mesh_processing.show()


## disable generating flag
func debug_unset_generating() -> void:
	self._debug_mesh_processing.hide()
	self._debug_mesh_idle.show()
	self.generation_mutex.unlock()



# --- Marching Cube Implementations ---

# table because godot can't do the god damn array read right.
# var table: Tables = Tables.new()


## Generates cube index of cube that starts with given vertex.
func _get_cube_idx(vert_zero: Vector3i) -> int:
	var cube_idx: int = 0

	# for each cube vert ... god I wish I had enumerate here
	for idx: int in range(8):

		# mark current edge's bit if height is above threshold
		if self._get_height(Tables.vert_idx_to_pos(vert_zero, idx)) > self.threshold:
			cube_idx |= 1 << idx

	return cube_idx


## Generate actual vertex pos from given cube index and logical vert_zero position.
func _generate_mesh_vertices(vert_zero: Vector3i, vert_arr: Array[Vector3]):
	# iso_level = height threshold in this implementation.
	# iso = greek 'isos', meaning 'equal'. So equal level!

	# get cube idx
	var cube_idx: int = self._get_cube_idx(vert_zero)

	# Get Array of crossed edges' indices for cube_idx. Triangulation step.
	# for each crossed edge idx in cube
	for edge_idx: int in Tables.CUBE_TO_TRI_EDGES_TABLE[cube_idx]:

		# lookup the cube verts that forms the edge
		var idx_a: int = Tables.EDGE_TO_VERT_A_TABLE[edge_idx];
		var idx_b: int = Tables.EDGE_TO_VERT_B_TABLE[edge_idx];

		# interpolate vertices for smooth mesh
		var vert_smooth: Vector3 = self._interpolate(
			self.threshold,
			Tables.vert_idx_to_pos(vert_zero, idx_a),
			Tables.vert_idx_to_pos(vert_zero, idx_b),
		)

		# or divide half for blockiness
		var vert_hard: Vector3 = (
			Vector3(vert_zero)
			+ (Tables.VERT_OFFSET_TABLE[idx_a] + Tables.VERT_OFFSET_TABLE[idx_b]) / 2.0
		)

		# mix those. more fine control > optimization here!
		var vert_mixed: Vector3 = lerp(vert_hard, vert_smooth, self.smoothness)

		# append to vert array with 0.0~1.0 normalization
		vert_arr.append(vert_mixed / self.width)


func _generate_vertex_arr() -> Array[Vector3]:
	var verts: Array[Vector3]

	for x in range(self.width):
		for y in range(self.width):
			for z in range(self.width):
				self._generate_mesh_vertices(Vector3i(x, y, z), verts)

	return verts


## Generate mesh from given vertices
func _generate_mesh(verts: Array[Vector3]) -> void:

	if not verts:
		self._mesh_instance.set_mesh.call_deferred(null)
		self._collision_shape.set_shape.call_deferred(null)
		return

	# setup surf tool
	var surf_tool := SurfaceTool.new()
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# smooth group will smooth ALL in same group. EVEN IF we didn't merge vertices. I luv ya!
	var smooth_group: int = -1 if self.flat_shading else 0

	var vert_idx: int = 0

	# somehow surfacetool still can automatically smooth non-merged vertices.
	# I assume it merges verts for us, so just mindlessly append vert
	for vert: Vector3 in verts:
		# we do uv using triplaner shader now, uv not needed

		var abs_vert: Vector3 = vert.abs()
		if abs_vert.x > 1 or abs_vert.y > 1 or abs_vert.z > 1:
			printerr("[MarchingCube] ERROR: vert %s out of chunk (%s)" % [vert_idx, vert])
			# push_error("[MarchingCube] ERROR: vert %s out of chunk (%s)" % [vert_idx, vert])

		surf_tool.set_smooth_group(smooth_group)
		surf_tool.add_index(vert_idx)
		surf_tool.add_vertex(vert)

		vert_idx += 1

	# gen normal & commit
	surf_tool.generate_normals()
	# surf_tool.generate_tangents()
	var _mesh: ArrayMesh = surf_tool.commit()

	# set mesh & collision shape
	self._mesh_instance.set_mesh.call_deferred(_mesh)
	self._collision_shape.set_shape.call_deferred(_mesh.create_trimesh_shape())


# --- Handlers ---

func _ready() -> void:
	self.position = self.pos
	self.recreate_grid()
