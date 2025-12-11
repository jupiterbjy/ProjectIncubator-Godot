class_name FreeCam
extends Node3D


# --- Exports ---

## Cam rotate speed
@export var cam_rotate_speed: float = 0.003

## Cam vertical abs. limit in rad
@export var cam_vertical_limit: float = PI / 2

## Pan responsiveness
@export var momentum_change_multiplier: float = 16.0

## Pan speed
@export var impulse_multiplier: float = 4.0


# --- Attributes ---

@onready var _azimuth: Node3D = self
@onready var _elevation: Node3D = $Elevation

@onready var cam: Node3D = $Elevation/Camera3D

## linear momentum of cam
var _impulse: Vector3 = Vector3.ZERO

var _is_rotating := false

## Mouse screen pos when rotating started
var _rotate_start_screen_pos: Vector2

## Azimuth rotation when rotating started
var _rot_start_az: float

## Elevation rotation when rotating started
var _rot_start_el: float


# --- Methods ---

## Aim camera toward global target
func look_pos(pos: Vector3) -> void:

	var local_pos := self.to_local(pos)
	self._azimuth.rotation.y = atan2(-local_pos.x, -local_pos.z)
	self._elevation.rotation.x = atan2(local_pos.y, -local_pos.z)

	self._update_reference_rotation()


func _update_reference_rotation() -> void:
	self._rot_start_az = self._azimuth.rotation.y
	self._rot_start_el = self._elevation.rotation.x


## Camera smooth wasd Movement with Backward+ / Right+
func _pan(ws: float, ad: float, vertical: float, delta: float):

	var forward: Vector3 = self._elevation.global_basis.z
	var left: Vector3 = self._elevation.global_basis.x
	var up: Vector3 = self._elevation.global_basis.y

	var new_vec: Vector3 = (
		forward * ws + left * ad + up * vertical
	).normalized() * delta

	# update impulse & move it
	self._impulse = lerp(self._impulse, new_vec, delta * self.momentum_change_multiplier)
	self.position += self._impulse * self.impulse_multiplier


func _rotate(diff: Vector2) -> void:
	# while mouse is down update rotation based on reference,
	# should reduce err compared to accumulator fashion

	self._azimuth.rotation.y = self._rot_start_az - diff.x * self.cam_rotate_speed
	self._elevation.rotation.x = clampf(
		self._rot_start_el - diff.y * self.cam_rotate_speed,
		-self.cam_vertical_limit,
		self.cam_vertical_limit
	)


# --- Handlers ---

func _unhandled_input(_event: InputEvent) -> void:
	# Usually following code is for _processing, but to allow UI take input and not return it
	# putting it here also do work.

	# if just clicked, set mouse down flag and record starting pos
	if Input.is_action_just_pressed(&"cam_rotate"):
		# print("Mouse down")
		self._is_rotating = true
		self._rotate_start_screen_pos = get_viewport().get_mouse_position()

	elif Input.is_action_just_released(&"cam_rotate"):
		# print("Mouse up")
		self._is_rotating = false
		self._update_reference_rotation()

	elif self._is_rotating:
		self._rotate(get_viewport().get_mouse_position() - self._rotate_start_screen_pos)


func _process(delta: float) -> void:

	# wasd
	var ws: float = Input.get_axis(&"move_forward", &"move_backward")
	var ad: float = Input.get_axis(&"move_left", &"move_right")
	var vertical: float = Input.get_axis(&"move_down", &"move_up")

	self._pan(ws, ad, vertical, delta)
