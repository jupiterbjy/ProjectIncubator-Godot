class_name RaycastManager extends Node3D


# --- Raycast support class ---


## Get ref to cam, viewport, world3d at init and reuse those to save overhead.
class RaycastInstance:
	var _cam: Camera3D
	var _viewport: Viewport
	var _world_3d: World3D
	var _mask: int
	var _collide_area: bool

	func _init(viewport: Viewport, world_3d: World3D, mask: int, collide_area) -> void:
		self._viewport = viewport
		self._cam = self._viewport.get_camera_3d()
		self._world_3d = world_3d
		self._mask = mask
		self._collide_area = collide_area

	## Perform raycast from mouse position.
	func raycast(max_distance: float = 200) -> Dictionary:
		var mouse_pos = self._viewport.get_mouse_position()
		var start = self._cam.project_ray_origin(mouse_pos)
		var end = start + self._cam.project_ray_normal(mouse_pos) * max_distance

		var query = PhysicsRayQueryParameters3D.create(start, end, self._mask)
		query.collide_with_areas = self._collide_area

		return self._world_3d.direct_space_state.intersect_ray(query)


## Build reusable raycasting instance
static func create_instance(
	viewport: Viewport, world_3d: World3D, mask: int, collide_area=false
) -> RaycastInstance:

	return RaycastInstance.new(viewport, world_3d, mask, collide_area)
