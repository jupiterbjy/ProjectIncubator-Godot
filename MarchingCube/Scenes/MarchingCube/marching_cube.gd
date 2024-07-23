class_name MarchingCube extends Node3D
## Godot marching cube implementation for Cube.
## Multithreading is not implemented.


static var tables: Tables = preload("res://Scenes/MarchingCube/Modules/tables.tscn").instantiate()
static var density_func: DensityFuncs = preload(
	"res://Scenes/MarchingCube/Modules/density_funcs.tscn"
).instantiate()


@export_group("Generation")

## Division
@export var width: int = 10

## Chunk's position
@export var chunk_pos: Vector3

## Noise generator
@export var noise: FastNoiseLite

## isovalue or threshold, deciding which value to be boundary of solid & empty
@export var threshold: float = 0.0

## Smoothness of generated mesh. 0.0 gives blocky feeling
@export_range(0.0, 1.0) var smoothness: float = 1.0


@export_group("Visual")

## Marker used for visualizing vertices
@export var vert_marker: PackedScene

## Decide whether to apply flat shading or not
@export var flat_shading: bool = false

@export_enum("3D", "3D Inverted", "2D", "Sphere") var density_type: int


# --- ready ---

@onready var _offset_node: Node3D = $Offset

@onready var _marker_root: Node3D = $Offset/MarkerRoot
@onready var _mesh_instance: MeshInstance3D = $Offset/MeshInstance
@onready var _collision_shape: CollisionShape3D = $Offset/StaticBody3D/CollisionShape3D

## Cache verts counts per edge
@onready var _w_verts: int = self.width + 1

## Cache squared verts count for indexing
@onready var _sq_w_verts: int = self._w_verts ** 2



# --- Height Grid ---
# NOTE: This are kept to allow fast update without regenerating whole grid

## 1-dim height array that is accessed via 3D array.
## Has size of width + 1, height + 1, width + 1.
var _heights: Array[float]


## Get height value at given coordinate
func _get_height(pos: Vector3i) -> float:
	return self._heights[self._sq_w_verts * pos.x + self._w_verts * pos.y + pos.z]


# --- Vertice Position Markers ---
# NOTE: This are kept to allow fast update without regenerating whole grid

## 1-dim marker array that is accessed via 3D array.
## Has size of width + 1, height + 1, width + 1.
var _markers: Array[MeshInstance3D]


## Get marker at given coordinate
func _get_marker(pos: Vector3i) -> MeshInstance3D:
	return self._markers[self._sq_w_verts * pos.x + self._w_verts * pos.y + pos.z]


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


## Normalize & Center logical coordinate so chunk is centered and scaled.
func _normalize_coordinate(logical_xyz: Vector3) -> Vector3:
	return (logical_xyz / self.width) - Vector3(0.5, 0.5, 0.5)


# --- Marching Cube Implementations

## Generates cube index of cube that starts with given vertex.
func _get_cube_idx(vert_zero: Vector3i) -> int:
	var cube_idx: int = 0

	# for each cube vert ... god I wish I had enumerate here
	for idx: int in range(8):

		# mark current edge's bit if height is above threshold
		if (self._get_height(self.tables.vert_idx_to_pos(vert_zero, idx)) > self.threshold):
			cube_idx |= 1 << idx

	return cube_idx


## Generate actual vertex pos from given cube index and logical vert_zero position.
func _generate_mesh_vertices(vert_zero: Vector3i, vert_arr: Array[Vector3]):
	# iso_level = height threshold in this implementation.
	# iso = greek 'isos', meaning 'equal'. So equal level!

	# get cube idx
	var cube_idx: int = self._get_cube_idx(vert_zero)

	# Get Array of crossed edges' indices for cube_idx. Triangulation step.
	var tri_edges: Array = self.tables.CUBE_TO_TRI_EDGES_TABLE[cube_idx]

	# for each crossed edge idx in cube
	for edge_idx: int in tri_edges:

		# lookup the cube verts that forms the edge
		var idx_a: int = self.tables.EDGE_TO_VERT_TABLE[edge_idx][0];
		var idx_b: int = self.tables.EDGE_TO_VERT_TABLE[edge_idx][1];

		# interpolate vertices for smooth mesh
		var vert_smooth: Vector3 = self._interpolate(
			self.threshold,
			self.tables.vert_idx_to_pos(vert_zero, idx_a),
			self.tables.vert_idx_to_pos(vert_zero, idx_b),
		)

		# or divide half for blockiness
		var vert_hard: Vector3 = (
			Vector3(vert_zero)
			+ (self.tables.VERT_OFFSET_TABLE[idx_a] + self.tables.VERT_OFFSET_TABLE[idx_b]) / 2.0
		)

		# mix those. more fine control > optimization here!
		var vert_mixed: Vector3 = lerp(vert_hard, vert_smooth, self.smoothness)

		# append to vert array
		vert_arr.append(self._normalize_coordinate(vert_mixed))


## Generate mesh from existing heights
func regenerate_mesh() -> void:

	# setup surf tool
	var surf_tool := SurfaceTool.new()
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# smooth group will smooth ALL in same group. EVEN IF we didn't merge vertices. I luv ya!
	var smooth_group: int = -1 if self.flat_shading else 0

	# added vertex counter & array
	# kinda afriad of fragmentation here
	var vert_idx: int = 0
	var verts: Array[Vector3]

	for x in range(self.width):
		for y in range(self.width):
			for z in range(self.width):
				self._generate_mesh_vertices(Vector3i(x, y, z), verts)

	# somehow surfacetool still can automatically smooth non-merged vertices.
	# I assume it merges verts for us, so just mindlessly append vert
	for vert: Vector3 in verts:

		# surf_tool.set_uv(Vector2(vert.x, vert.z))
		# we do uv using triplaner shader now, not needed nor seemingly possible

		surf_tool.set_smooth_group(smooth_group)
		surf_tool.add_index(vert_idx)
		surf_tool.add_vertex(vert)

		vert_idx += 1

	# gen normal & commit
	surf_tool.generate_normals()
	var _mesh: ArrayMesh = surf_tool.commit()

	# set mesh & collision shape
	self._mesh_instance.mesh = _mesh
	self._collision_shape.shape = _mesh.create_trimesh_shape()


## Set noise & update marker. Does not regenerate mesh.
func _resample_density() -> void:

	for x in range(self._w_verts):
		var x_flat_idx: int = self._sq_w_verts * x

		for y in range(self._w_verts):
			var y_flat_idx: int = self._w_verts * y

			for z in range(self._w_verts):
				var flat_idx = x_flat_idx + y_flat_idx + z

				# we're dividing by vert width to make sure UV 1:1 match width
				var height: float = self.density_func.sample_density(
					self.noise,
					self._normalize_coordinate(Vector3(x, y, z)),
					self.chunk_pos,
					self.density_type,
				)

				self._heights[flat_idx] = height

				self._markers[flat_idx].set_height(height)
				self._markers[flat_idx].visible = height < self.threshold


# --- Grid management ---
# Convenient helper methods that repopulate grid's arrays.
# For actual in-game usage, these are probably not needed.

## Creates new grid filled with 1.0.
func _recreate_grid() -> void:

	# destroy
	for node: Node3D in self._markers:
		node.queue_free()

	self._markers.clear()
	self._heights.clear()

	# recreate
	var flat_size: int = self._w_verts ** 3

	self._markers.resize(flat_size)
	self._heights.resize(flat_size)
	self._heights.fill(1.0)

	# generate markers
	self._create_markers()


## Creates debug markers
func _create_markers() -> void:

	for x in range(self._w_verts):
		var x_flat_idx: int = self._sq_w_verts * x

		for y in range(self._w_verts):
			var y_flat_idx: int = self._w_verts * y

			for z in range(self._w_verts):
				# instance vert marker
				var instance: Node3D = self.vert_marker.instantiate()

				self._marker_root.add_child(instance)
				instance.position = self._normalize_coordinate(Vector3(x, y, z))

				self._markers[x_flat_idx + y_flat_idx + z] = instance


# --- Interfaces ---
# Convenient helper methods that sets parameter & regenerate mesh as needed.
# For actual in-game usage, most of is probably not needed.

## Dump all mesh, verts, markers and regenerate from scratch.
## Since this is expensive call when:
## - initializing
## - width change
func regenerate_all() -> void:
	self._recreate_grid()
	self._resample_density()
	self.regenerate_mesh()



## Convenience setup func for setting threshold. Updates mesh.
## Set threshold (or iso level) only. Only shows verts that's below threshold.
## Height above 0 will be empty while belows become solid.
func set_threshold(new_threshold: float) -> void:
	self.threshold = new_threshold

	for x in range(self._w_verts):
		var x_flat_idx: int = self._sq_w_verts * x

		for y in range(self._w_verts):
			var y_flat_idx: int = self._w_verts * y

			for z in range(self._w_verts):
				var flat_idx: int = x_flat_idx + y_flat_idx + z
				self._markers[flat_idx].visible = self._heights[flat_idx] < self.threshold

	# we only need to regenerate mesh, right?
	# ...right?
	self.regenerate_mesh()
	# yeah I think it was, good job old me


## Convenient setup func for setting width.
## Regenerates entire grid from scratch.
func set_width(new_width: float) -> void:
	self.width = int(new_width)

	self._w_verts = self.width + 1
	self._sq_w_verts = self._w_verts ** 2

	self.regenerate_all()


## Convenience function for changing chunk position.
## Regenerates noise and mesh.
func set_chunk_pos(new_chunk_pos: Vector3) -> void:
	self.chunk_pos = new_chunk_pos
	self._resample_density()
	self.regenerate_mesh()


## Convenience function for changing blending factor.
func set_blending_factor(factor: float) -> void:
	var mat: ShaderMaterial = self._mesh_instance.get_active_material(0)
	mat.set_shader_parameter("BlendFactor", factor)


## Convenience wrapper for setting noise seed. Regenerate noise & mesh.
func set_noise_seed(new_seed: int) -> void:
	self.noise.seed = new_seed
	self._resample_density()
	self.regenerate_mesh()


## Set noise scale
func set_noise_frequency(new_freq: float) -> void:
	self.noise.frequency = new_freq
	self._resample_density()
	self.regenerate_mesh()


## Set noise offset
func set_noise_offset(new_offset: Vector3) -> void:
	self.noise.offset = new_offset
	self._resample_density()
	self.regenerate_mesh()
