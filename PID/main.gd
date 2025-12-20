extends Control


# --- Classes ---

## AIO PID manager. Slap this bastard & adjust limit then tune pid.
class PIDManager:
	# ref: https://en.wikipedia.org/wiki/PID_controller
	# ref: https://www.steppeschool.com/blog/pid-implementation-in-c

	var kp: float = 1
	var ki: float = 1
	var kd: float = 1

	var last_err: float = 0
	var integral: float = 0

	var integral_max: float = 10
	var pid_max: float = 20
	var integral_cutoff: float = 0.05

	## Calculate PID controller output from given error.
	func calc(err: float, delta: float) -> float:

		var delta_err := err - self.last_err
		self.last_err = err

		# limit maximum integral
		self.integral = clampf(self.integral + err, -self.integral_max, self.integral_max)

		# integral cutoff to prevent oscillation
		if absf(err) < self.integral_cutoff:
			self.integral = 0.

		# limit final output
		return clampf(
			self.kp * err
			+ self.ki * self.integral * delta
			+ self.kd * delta_err / delta,
			-pid_max,
			pid_max,
		)


# --- Attributes ---

@onready var switch: TextureButton = %Switch

@onready var pointer: AnglePointer = %AnglePointer

@onready var input_dial: Dial = %InputDial
@onready var p_dial: Dial = %PDial
@onready var i_dial: Dial = %IDial
@onready var d_dial: Dial = %DDial

@onready var control_graph_output: ControlGraph = %ControlGraphOutput
@onready var control_graph_last_error: ControlGraph = %ControlGraphLastError
@onready var control_graph_integral: ControlGraph = %ControlGraphIntegral
@onready var control_graph_delta_error: ControlGraph = %ControlGraphDeltaError

@onready var latency_label: Label = %LatencyLabel
@onready var cap_label: Label = %CapLabel

var pid_manager := PIDManager.new()


# --- Handlers ---

func _ready() -> void:

	# reset params to match current dial val
	self.pid_manager.kp = self.p_dial.value
	self.pid_manager.ki = self.i_dial.value
	self.pid_manager.kd = self.d_dial.value

	# update labels for constant-ish-values
	self.latency_label.text = self.latency_label.text % self.pointer.delay_sec
	self.cap_label.text = self.cap_label.text % self.pid_manager.integral_cutoff

	# recording res mode
	#self.get_window().size *= 2.0
	#self.get_window().move_to_center()


func _physics_process(delta: float) -> void:

	var factor: float = 1.0
	var delta_err: float = 0.0

	var input_val := self.input_dial.value if self.switch.button_pressed else 0.0

	var err: float = self.pointer.value - input_val
	delta_err = err - self.pid_manager.last_err

	# apply pid & punch it
	factor *= self.pid_manager.calc(err, delta)
	self.pointer.apply_torque(factor * 20.0)

	# update graphs
	self.control_graph_output.add_point(factor)
	self.control_graph_last_error.add_point(self.pid_manager.last_err)
	self.control_graph_integral.add_point(self.pid_manager.integral)
	self.control_graph_delta_error.add_point(delta_err)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_switch"):
		self.switch.button_pressed = not self.switch.button_pressed


func _on_p_dial_value_changed(val: float) -> void:
	self.pid_manager.kp = val


func _on_i_dial_value_changed(val: float) -> void:
	self.pid_manager.ki = val


func _on_d_dial_value_changed(val: float) -> void:
	self.pid_manager.kd = val
