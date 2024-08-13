extends Node3D


# --- Exports ---

## PackedScene that contains pointcloud mesh.
## This is to create multile chunks for faster generation.
@export var point_cloud_scene: PackedScene


# --- References ---

## Displays total points
@onready var point_count_label: Label = %PointStatLabel

## Displays points in array
@onready var arr_stat_label: Label = %ArrayStatLabel

## Displays mesh count
@onready var mesh_count_label: Label = %MeshStatLabel

## Subviewport's raycast scene instance for faster acess
@onready var raycast_scene_instance: RaycastScene = %RaycastScene

@onready var az_axis: Node3D = $AzimuthTurntable
@onready var el_axis: Node3D = $AzimuthTurntable/ElevationTurntable

## Totall pointcloud mesh count
var mesh_count: int = 0

## Current actively updated pointcloud's array mesh
var active_arr_mesh: ArrayMesh = null

## Total cumulative point count
var total_points: int = 0

## Current active surface tool
var surf_tool: SurfaceTool = null


# --- Init ---

func _ready() -> void:
	self.raycast_scene_instance.lidar_cursor = %ScanCursor

	# add initial pointcloud mesh
	self.create_new_pointcloud()


# --- Utility ---

## Add new pointcloud mesh instance and update references.
## Originally had mesh seperation on every n points, but removed as there wasn't much perf gain.
## So this is only used in _ready(). poor lil' thing.
func create_new_pointcloud() -> void:
	print("[Main] Creating new pointcloud!")

	var instance: MeshInstance3D = self.point_cloud_scene.instantiate()
	self.el_axis.add_child(instance)

	# update ref
	self.active_arr_mesh = instance.mesh

	self.surf_tool = SurfaceTool.new()
	self.surf_tool.begin(Mesh.PRIMITIVE_POINTS)

	# update counter
	self.mesh_count += 1
	%MeshStatLabel.text = "%s mesh(s)" % self.mesh_count


# --- Logic ---



## Updates pointcloud array mesh.
func update_pointcloud():

	for idx: int in range(self.raycast_scene_instance.point_count):
		surf_tool.set_color(self.raycast_scene_instance.colors[idx])
		surf_tool.add_vertex(self.raycast_scene_instance.points[idx])

	# SurfaceTool.commit(existing_arr_mesh) creates new 'surface' every call
	# so need to recreate from scratch
	self.active_arr_mesh.clear_surfaces()
	surf_tool.commit(self.active_arr_mesh)

	self.total_points += self.raycast_scene_instance.point_count
	self.raycast_scene_instance.clear_arr()


## Perform scan
func scan_once() -> void:

	# scan
	self.raycast_scene_instance.scan_once()

	# update label
	self.arr_stat_label.text = "%s / %s points in buffer" % [
		self.raycast_scene_instance.point_count, len(self.raycast_scene_instance.points)
	]
	self.point_count_label.text = "%s points total" % (
		self.total_points + self.raycast_scene_instance.point_count
	)


# --- Driver ---

func _process(delta: float) -> void:

	# rotate object around
	# unlike cam rotation axis is reversed (honestly unintuitive to me why that is)
	self.az_axis.rotate_x(delta * -0.2)
	self.el_axis.rotate_y(delta * -0.1)


var _tick: bool = true

# Adjust physic frame per second to adjust scan speed.
func _physics_process(_delta: float) -> void:

	# scan and call pointcloud later
	if self._tick:
		self.scan_once()
	else:
		self.update_pointcloud()

	self._tick = not self._tick
