class_name Dial
extends Control
## UI Dial. Yeah that's it


# --- Signals ---

signal value_changed(val: float)


# --- Exports ---

@export var max_val: float = 1.0

@export var value: float = 0.0


# --- Attributes ---

@onready var _knob: Control = $Knob
@onready var _label: Label = $Label

@onready var _start_angle: float = self._knob.rotation
@onready var _end_angle: float = -self._knob.rotation
@onready var _angle_range: float = self._end_angle - self._start_angle


# --- Methods ---

func set_value(val: float) -> void:
	self._knob.rotation = self._angle_range * (self.value / self.max_val) + self._start_angle

	self.value = clampf(val, 0.0, self.max_val)
	self._label.text = "%4.2f" % self.value
	self.value_changed.emit(val)


# --- Handlers ---

func _ready() -> void:
	self.set_value(self.value)


func _on_gui_input(event: InputEvent) -> void:

	var rel_pos := Vector2.ZERO

	if event is InputEventScreenTouch:
		rel_pos = self._knob.position - (event as InputEventScreenTouch).position

	elif event is InputEventScreenDrag:
		rel_pos = self._knob.position - (event as InputEventScreenDrag).position

	else:
		return

	# calc touch angle with flipped axes since we want angle start from 6 o'clock
	var angle := clampf(-atan2(rel_pos.x, rel_pos.y), self._start_angle, self._end_angle)
	self._knob.rotation = angle

	self.value = (angle - self._start_angle) * self.max_val / self._angle_range
	self._label.text = "%4.2f" % self.value
	self.value_changed.emit(self.value)
