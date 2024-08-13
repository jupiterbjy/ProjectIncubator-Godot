class_name RaycastScene extends Node3D
## Raycasting node for use in subviewport.


# --- Exports ---

## Collision type. Use convex for simpler shape, trimesh for complex shape.
@export_enum("Convex", "Trimesh") var collision_type: int

## Scan points per cursor line. Higher the points, worsen the performance.
## This is due to screen texture fetch cost. (GPU VRAM -> CPU RAM copy)
@export var points_per_cursor: int = 30

## Max array buffer size.
@export var arr_size: int = 2 ** 10


# --- References ---

@onready var ray_cam: Camera3D = %RayCamera3D

@onready var az_axis: Node3D = $AzimuthTurntable
@onready var el_axis: Node3D = $AzimuthTurntable/ElevationTurntable

@onready var viewport: SubViewport = self.get_parent()

# control node to sample screen area from. set this from parent.
var lidar_cursor: Control = null

# extracted points pos buffer. Use packed arr for speed
var colors: PackedColorArray

# extracted points color buffer. Use packed arr for speed
var points: PackedVector3Array

# point count, since we don't want to check how many are in packed array manually
var point_count: int = 0

# raycast length
static var _RAY_LENGTH: float = 100.0

# raycast collision mask
static var _RAY_MASK: int = 1

# cached world 3D
@onready var world_3d: World3D = get_world_3d()


# --- Utility ---

## Raycast from given screen position and returns query result
func raycast_from_screen(pos: Vector2i) -> Dictionary:

	# get ray start & end
	var from: Vector3 = ray_cam.project_ray_origin(pos)
	var to: Vector3 = from + ray_cam.project_ray_normal(pos) * self._RAY_LENGTH

	# perform raycast
	var space_state := self.world_3d.direct_space_state

	var query := PhysicsRayQueryParameters3D.create(from, to, self._RAY_MASK)

	return space_state.intersect_ray(query)


## Reset array position. Actually just sets item index to 0 without clearing.
func clear_arr() -> void:
	self.point_count = 0


## Checks if array's almost full
func is_almost_full() -> bool:
	var length: int = len(self.points)

	if length - self.point_count < self.points_per_cursor:
		print("[RaycastScene] Array almost full! (%s / %s)" % [self.point_count, length])
		return true

	return false


# --- Logic ---

## Scan the lidar cursor area and extract point's position and color if any.
## scanned_perc is in range(0.0~1.0) and represent how many % of points are scanned.
func scan_area(scanned_perc: float, screen_tex: Texture2D) -> void:

	# blend between lidar cursor position to get equally spaced scan points
	var screen_pos: Vector2i = floor(lerp(
		self.lidar_cursor.position,
		self.lidar_cursor.position + self.lidar_cursor.size,
		scanned_perc,
	))

	# do raycast and fetch result
	var result := self.raycast_from_screen(screen_pos)

	# if not hit ignore
	if not result:
		return

	# else get screen color
	var color: Color = screen_tex.get_image().get_pixelv(screen_pos)

	# append to arr
	self.colors[self.point_count] = color
	self.points[self.point_count] = result["position"]
	self.point_count += 1


# --- Driver ---

func _ready() -> void:
	# prealloctate packedarray
	self.colors.resize(self.arr_size)
	self.points.resize(self.arr_size)

	# generate static collision shape from mesh so we don't have to press in GUI
	# when changing meshes
	if self.collision_type == 0:
		%MeshInstance3D.create_convex_collision()
	elif self.collision_type == 1:
		%MeshInstance3D.create_trimesh_collision()


func _process(delta: float) -> void:

	# rotate cam around neko
	self.az_axis.rotate_y(delta * 0.1)
	self.el_axis.rotate_x(delta * 0.2)


var next_v_pos: int = 0


## Scans at scan cursor position once.
func scan_once():

	# fetch screen texture here to save GPU-CPU IO
	var screen_tex: Texture2D = self.viewport.get_texture()

	# scan multiple times per line sweep
	for idx: int in range(self.points_per_cursor):
		self.scan_area(idx / float(self.points_per_cursor), screen_tex)
