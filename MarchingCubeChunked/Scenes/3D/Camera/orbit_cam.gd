class_name OrbitCam extends Node3D
## Orbiting cam using mouse click and scroll
##
## jupiterbjy@gmail.com


# --- Exports ---

## Cam Max zoomed in Distance Multiplier
@export var zoom_multiplier_min: float = 0.3

## Cam Max zoomed out Distance Multiplier
@export var zoom_multiplier_max: float = 6.0

## Cam rotate speed
@export var cam_rotate_speed: float = -0.003

## Cam vertical abs. limit in rad
@export var cam_vertical_limit: float = PI / 2

## Starting zoom level
@export var zoom_start: float = 3.0

## Zoom unit
@export var zoom_unit: float = 0.1


# --- References ---

@onready var _azimuth_axis: Node3D = $Azimuth
@onready var _elevation_axis: Node3D = $Azimuth/Elevation
@onready var _cam: Node3D = $Azimuth/Elevation/Camera3D

# NOTE: caches are used to reset cam
@onready var _azimuth_transform_cache: Transform3D = self._azimuth_axis.transform
@onready var _elevation_transform_cache: Transform3D = self._elevation_axis.transform
@onready var _cam_local_pos_cache: Vector3 = self._cam.position

@onready var _cam_max_distance: Vector3 = self.zoom_multiplier_max * self._cam_local_pos_cache
@onready var _cam_min_distance: Vector3 = self.zoom_multiplier_min * self._cam_local_pos_cache


func _ready() -> void:
	self.zoom_absolute(self.zoom_start)
	print("[OrbitCam] Init")


# --- Cam Actions ---

# usually just adding InputEvent.relative is enough, but to prevent
# drift I'm using mouse down timing as reference point and overwrite rotation.

## keeps azimuth's y axis rotation when mouse just clicked
var _ref_azimuth_rotation: float

## Keeps elevation's x axis rotation when mouse just clicked.
var _ref_elevation_rotation: float


## Get initial click ~ current mouse pos diff and update rotation from it.
func rotate_view(diff: Vector2):

	self._azimuth_axis.rotation.y = self._ref_azimuth_rotation + diff.x * self.cam_rotate_speed

	# limit Y
	self._elevation_axis.rotation.x = clampf(
		self._ref_elevation_rotation + diff.y * self.cam_rotate_speed,
		-self.cam_vertical_limit,
		self.cam_vertical_limit
	)


## Update reference to current rotation value on mouse release
func update_reference():
	self._ref_azimuth_rotation = self._azimuth_axis.rotation.y
	self._ref_elevation_rotation = self._elevation_axis.rotation.x


## Reset cam rotations
func reset_cam():
	self._azimuth_axis.transform = self._azimuth_transform_cache
	self._elevation_axis.transform = self._elevation_transform_cache
	self._cam.position = self._cam_local_pos_cache

	# reset reference points too in case still in mouse down aka in rotation state
	self.update_reference()



func zoom_absolute(amount: float):
	self._cam.position = clamp(
		self._cam_local_pos_cache * amount,
		self._cam_min_distance,
		self._cam_max_distance
	)


func zoom_relative(amount: float):
	self._cam.position = clamp(
		self._cam.position - self._cam_local_pos_cache * amount,
		self._cam_min_distance,
		self._cam_max_distance
	)


## Zoom in, yeah
func zoom_in():
	self.zoom_relative(self.zoom_unit)


## Zoom out, also yeah
func zoom_out():
	self.zoom_relative(-self.zoom_unit)


var impulse: Vector3 = Vector3.ZERO

@export var momentum_change_multiplier: float = 16.0
@export var impulse_multiplier: float = 4.0


## Camera wasd Movement with Backward+ / Right+
func pan(ws: float, ad: float, delta: float):
	# Use azimuth vectors
	var forward: Vector3 = self._azimuth_axis.basis.z
	var left: Vector3 = self._azimuth_axis.basis.x

	var new_vec: Vector3 = (forward * ws + left * ad).normalized() * delta
	self.impulse = lerp(self.impulse, new_vec, delta * self.momentum_change_multiplier)
	self.position += self.impulse * self.impulse_multiplier



# --- Input processor ---

var is_mouse_rotate_down := false
var mouse_rotate_down_screen_pos: Vector2


func _unhandled_input(_event: InputEvent) -> void:
	# Usually following code is for _processing, but to allow UI take input and not return it
	# putting it here also do work.

	# if just clicked, set mouse down flag and record starting pos
	if Input.is_action_just_pressed("cam_rotate"):
		# print("Mouse down")
		self.is_mouse_rotate_down = true
		self.mouse_rotate_down_screen_pos = get_viewport().get_mouse_position()

	elif Input.is_action_just_released("cam_rotate"):
		# print("Mouse up")
		self.is_mouse_rotate_down = false
		self.update_reference()

	elif self.is_mouse_rotate_down:
		# while mouse is down update rotation
		self.rotate_view(get_viewport().get_mouse_position() - self.mouse_rotate_down_screen_pos)

	# process zoom
	if Input.is_action_just_pressed("cam_zoom_in"):
		self.zoom_in()

	elif Input.is_action_just_pressed("cam_zoom_out"):
		self.zoom_out()

	if Input.is_action_just_pressed("cam_reset"):
		self.reset_cam()


var mouse_pan_down_screen_pos: Vector2
@export var mouse_pan_sensitivity: float = 0.1
@export var mouse_pan_deadzone: float = 16.0
@export var mouse_pan_max_speed_dist: float = 100.0


# Screen Pan control
func _pan_control(delta: float) -> void:
	if Input.is_action_just_pressed("cam_pan"):
		self.mouse_pan_down_screen_pos = get_viewport().get_mouse_position()
		return

	elif Input.is_action_just_released("cam_pan"):
		return

	elif Input.get_action_strength("cam_pan"):
		# TODO: add deadzone

		var new_pos := get_viewport().get_mouse_position()
		var diff := get_viewport().get_mouse_position() - self.mouse_pan_down_screen_pos
		var distance := diff.length()

		# if within deadzone fuse out
		if distance < self.mouse_pan_deadzone:
			self.pan(0.0, 0.0, delta)
			return

		# else cap the size
		if distance > self.mouse_pan_max_speed_dist:
			diff = diff.normalized() * self.mouse_pan_max_speed_dist

		self.pan(
			diff.y * self.mouse_pan_sensitivity,
			diff.x * self.mouse_pan_sensitivity,
			delta
		)
		return


func _process(delta: float) -> void:
	self._pan_control(delta)

	# wasd
	var ws: float = (
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)

	var ad: float = (
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	)

	self.pan(ws, ad, delta)
