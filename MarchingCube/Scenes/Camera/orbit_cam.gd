class_name OrbitCam extends Node3D
## Orbiting cam using mouse click and scroll.
## Can rotate, pinch to zoom and triple tab to reset view.
##
## jupiterbjy@gmail.com


# --- Camera param ---

## Cam Max zoomed in Distance Multiplier
@export var fov_min_mult: float = 0.3

## Cam Max zoomed out Distance Multiplier
@export var fov_max_mult: float = 1.3

## Cam rotate speed
@export var cam_rotate_speed: float = -0.003

## Cam vertical abs. limit in rad
@export var cam_vertical_limit: float = PI / 2

## Starting azimuth in rad
@export var starting_azimuth: float = 0.0

## Starting elevation in rad
@export var starting_elevation: float = PI / 3

## Starting zoom level
@export var starting_fov_mult: float = 0.8

# --- Onreadies ---

@onready var _azimuth_axis: Node3D = $Azimuth
@onready var _elevation_axis: Node3D = $Azimuth/Elevation
@onready var _cam: Camera3D = $Azimuth/Elevation/Camera3D

# NOTE: caches are used to reset cam
@onready var _azimuth_transform_cache: Transform3D = self._azimuth_axis.transform
@onready var _elevation_transform_cache: Transform3D = self._elevation_axis.transform
@onready var _cam_local_pos_cache: Vector3 = self._cam.position

@onready var _default_fov: float = self._cam.fov


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


## Update reference to current rotation value on mouse release.
## This prevents cam rotation being 'reset'.
func update_reference():
	self._ref_azimuth_rotation = self._azimuth_axis.rotation.y
	self._ref_elevation_rotation = self._elevation_axis.rotation.x


## Reset cam rotations
func reset_cam():
	self._azimuth_axis.transform = self._azimuth_transform_cache
	self._elevation_axis.transform = self._elevation_transform_cache
	self._cam.fov = self._default_fov

	# reset reference points too in case still in mouse down aka in rotation state
	self.update_reference()


@onready var _current_fov_mult: float = self.starting_fov_mult


## Set zoom level
func zoom(level: float):
	self._current_fov_mult = clampf(level, self.fov_min_mult, self.fov_max_mult)
	self._cam.fov = self._default_fov * self._current_fov_mult


## Zoom in, yeah
func zoom_in():
	self.zoom(self._current_fov_mult - 0.1)


## Zoom out, also yeah
func zoom_out():
	self.zoom(self._current_fov_mult + 0.1)


# --- Input processor ---

var is_mouse_down := false
var mouse_down_screen_pos: Vector2


func _unhandled_input(_event: InputEvent) -> void:
	# Usually following code is for _processing, but to allow UI take input and not return it
	# putting it here also do work.

		# if just clicked, set mouse down flag and record starting pos
	if Input.is_action_just_pressed("click"):
		self.is_mouse_down = true
		self.mouse_down_screen_pos = get_viewport().get_mouse_position()

	elif Input.is_action_just_released("click"):
		self.is_mouse_down = false
		self.update_reference()

	elif self.is_mouse_down:
		# while mouse is down update rotation
		self.rotate_view(get_viewport().get_mouse_position() - self.mouse_down_screen_pos)

	# process zoom
	if Input.is_action_just_pressed("cam_zoom_in"):
		self.zoom_in()

	elif Input.is_action_just_pressed("cam_zoom_out"):
		self.zoom_out()

	if Input.is_action_just_pressed("cam_reset"):
		self.reset_cam()


# --- Ready ---

func _ready() -> void:
	# set initial param
	# feels like we need better way..
	self._elevation_axis.rotation.x = -self.starting_elevation
	self._azimuth_axis.rotation.y = self.starting_azimuth
	self.update_reference()

	self.zoom(self.starting_fov_mult)

	# update defaults excl. zoom
	self._azimuth_transform_cache = self._azimuth_axis.transform
	self._elevation_transform_cache = self._elevation_axis.transform
