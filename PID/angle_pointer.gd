class_name AnglePointer
extends Control


# --- Exports ---

@export_range(0.01, 0.1, 0.01) var delay_sec: float = 0.05

@export_range(0.0, 0.05, 0.95) var friction_factor: float = 0.95


# --- Attributes ---

@onready var _knob: Control = $Knob
@onready var _label: Label = $Label

@onready var _start_angle: float = self._knob.rotation
@onready var _end_angle: float = -self._knob.rotation
@onready var _angle_range: float = self._end_angle - self._start_angle

var value: float = 0.0

var _moment: float = 0.0

var _force_delay_arr: PackedFloat32Array
var _read_idx: int = 0
var _write_idx: int = -1


# --- Methods ---

## Applies torque. (Positive -> Clockwise)
func apply_torque(torque: float) -> void:
	self._force_delay_arr[self._write_idx] = torque


# --- Handlers ---

func _ready() -> void:
	# gonna set 0.1 sec delay
	var project_fps: int = ProjectSettings.get_setting("application/run/max_fps")
	self._force_delay_arr.resize(ceili(float(project_fps) * self.delay_sec))


func _process(delta: float) -> void:

	# apply delayed torque
	self._moment -= self._force_delay_arr[self._read_idx] * delta

	# simulate motion with capping
	var rot := self._knob.rotation + self._moment * delta

	if rot < self._start_angle:
		self._moment = 0.0
		self._knob.rotation = self._start_angle

	elif rot > self._end_angle:
		self._moment = 0.0
		self._knob.rotation = self._end_angle
	else:
		self._knob.rotation = rot

	# apply some fictional friction
	self._moment *= self.friction_factor

	# update val & indices
	self.value = (self._knob.rotation - self._start_angle) / self._angle_range
	self._label.text = "%4.2f" % self.value

	self._read_idx = (self._read_idx + 1) % len(self._force_delay_arr)
	self._write_idx = self._read_idx - 1
	# ^^^ since godot support negative index this is fine
