extends Node3D


# --- References ---

@onready var arr_mesh: ArrayMesh = %MeshInstance3D.mesh

@onready var lidar_scan_bar: ColorRect = %ColorRect

@onready var point_count_label: Label = %Label

@onready var raycast_scene: Node3D = %RaycastScene

@onready var az_axis: Node3D = $AzimuthTurntable
@onready var el_axis: Node3D = $AzimuthTurntable/ElevationTurntable


# --- Init ---

func _ready() -> void:
	self.raycast_scene.lidar_cursor = %ColorRect


# --- Logic ---


func _on_timer_timeout() -> void:
	# on timer, update mesh with new vertices from raycast scene
	
	if not self.raycast_scene.points:
		return
	
	var surf_tool := SurfaceTool.new()
	surf_tool.begin(Mesh.PRIMITIVE_POINTS)
	
	for idx: int in range(len(self.raycast_scene.points)):
		surf_tool.set_color(self.raycast_scene.colors[idx])
		surf_tool.add_vertex(self.raycast_scene.points[idx])
	
	# SurfaceTool.commit(existing_arr_mesh) creates new 'surface' every call
	# so need to recreate from scratch
	self.arr_mesh.clear_surfaces()
	surf_tool.commit(self.arr_mesh)
	
	self.point_count_label.text = "%s / %s points" % [self.raycast_scene.point_count, len(self.raycast_scene.points)]


func _physics_process(delta: float) -> void:
	
	# rotate object around
	# WHY THE F X AND Y IS REVERSED??
	self.az_axis.rotate_x(delta * -0.2)
	self.el_axis.rotate_y(delta * -0.1)
