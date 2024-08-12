extends Node3D


@onready var cam: Camera3D = $Turntable/Camera3D
@onready var arr_mesh: ArrayMesh = $MeshInstance3D.mesh


var ray_length: float = 100.0
var ray_mask: int = 1


var colors: Array[Color]
var points: Array[Vector3]


## Raycast from given screen position and returns query result
func raycast_from_screen(pos: Vector2) -> Dictionary:
	
	# get ray start & end
	var from: Vector3 = cam.project_ray_origin(pos)
	var to: Vector3 = from + cam.project_ray_normal(pos) * self.ray_length
	
	# perform raycast
	var space_state := get_world_3d().direct_space_state
	
	var query := PhysicsRayQueryParameters3D.create(from, to, self.ray_mask)
	query.collide_with_areas = true
	
	return space_state.intersect_ray(query)


func _physics_process(delta: float) -> void:
	$Turntable.rotate_y(delta * 0.1)
	
	var screen_size: Vector2i = DisplayServer.window_get_size()
	var rand_screen_pos := Vector2i(
		randi_range(0, screen_size.x),
		randi_range(0, screen_size.y),
	)
	
	var result := self.raycast_from_screen(rand_screen_pos)
	
	# if not hit ignore
	if not result:
		return
	
	# else if hit get screen color
	var color = get_viewport().get_texture().get_image().get_pixelv(rand_screen_pos)
	
	# write point
	self.colors.append(color)
	self.points.append(result["position"])


func _on_timer_timeout() -> void:
	# update mesh
	
	if not self.points:
		return
	
	var surf_tool := SurfaceTool.new()
	surf_tool.begin(Mesh.PRIMITIVE_POINTS)
	
	for idx: int in range(len(self.points)):
		surf_tool.set_color(self.colors[idx])
		surf_tool.add_vertex(self.points[idx])
	
	surf_tool.commit(self.arr_mesh)
	
	print("[Main] Added %s verts" % len(self.colors))
	
	self.colors.clear()
	self.points.clear()
	
