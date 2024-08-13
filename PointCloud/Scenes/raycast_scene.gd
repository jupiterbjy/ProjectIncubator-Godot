extends Node3D


# --- References ---

@onready var ray_cam: Camera3D = %RayCamera3D

@onready var az_axis: Node3D = $AzimuthTurntable
@onready var el_axis: Node3D = $AzimuthTurntable/ElevationTurntable

@onready var viewport: SubViewport = self.get_parent()

# control node to sample screen area from. set this from parent.
var lidar_cursor: Control = null

# extracted points pos. Use packed arr for speed
var colors: PackedColorArray

# extracted points color. Use packed arr for speed
var points: PackedVector3Array

# point count, since we don't want to check how many are in packed array manually
var point_count: int = 0

# raycast length
static var _RAY_LENGTH: float = 100.0

# raycast collision mask
static var _RAY_MASK: int = 1

# scan points count per scan line
static var _POINTS_PER_CURSOR: int = 20

# starting packedarray size
static var _ARR_INIT_SIZE: int = 4096


# --- Utility ---

## Raycast from given screen position and returns query result
func raycast_from_screen(pos: Vector2i) -> Dictionary:
	
	# get ray start & end
	var from: Vector3 = ray_cam.project_ray_origin(pos)
	var to: Vector3 = from + ray_cam.project_ray_normal(pos) * self._RAY_LENGTH
	
	# perform raycast
	var space_state := get_world_3d().direct_space_state
	
	var query := PhysicsRayQueryParameters3D.create(from, to, self._RAY_MASK)
	query.collide_with_areas = true
	
	return space_state.intersect_ray(query)


## Get pixel color from given screen position
func get_screen_color(pos: Vector2i) -> Color:
	return self.viewport.get_texture().get_image().get_pixelv(pos)


# --- Logic ---

## Scan the lidar cursor area and extract point's position and color if any.
## scanned_perc is in range(0.0~1.0) and represent how many % of points are scanned.
func scan_area(scanned_perc: float) -> void:
	
	# in case you just need random = not sure code is correct now, didn't updated
	#var rand_screen_pos := Vector2i(
		#int(self.lidar_scan_bar.global_position.x),
		#randi_range(0, int(self.lidar_scan_bar.size.y)) + Vector2i(self.lidar_scan_bar.global_position).y,
	#)
	
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
	var color: Color = self.get_screen_color(screen_pos)
	
	# append to arr
	self.colors[self.point_count] = color
	self.points[self.point_count] = result["position"]
	self.point_count += 1


# --- Driver ---

func _ready() -> void:
	# prealloctate packedarray
	self.colors.resize(self._ARR_INIT_SIZE)
	self.points.resize(self._ARR_INIT_SIZE)
	
	# TODO: create collision shape in code


func _physics_process(delta: float) -> void:
	
	# rotate cam around neko
	self.az_axis.rotate_y(delta * 0.1)
	self.el_axis.rotate_x(delta * 0.2)
	
	# scan multiple times per line sweep
	for idx: int in range(_POINTS_PER_CURSOR):
		self.scan_area(idx / float(_POINTS_PER_CURSOR))

	# if size is in danger expand packedarrays twice of current size
	var length: int = len(self.points)
	
	if length - self.point_count < _POINTS_PER_CURSOR:
		print("[RaycastScene] Resizing array! (%s → %s)" % [length, length * 2])
		self.points.resize(length * 2)
		self.colors.resize(length * 2)
