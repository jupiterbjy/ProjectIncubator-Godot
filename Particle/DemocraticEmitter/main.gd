extends Node3D


@onready var left_emitter: DemocraticEmitter = $DemocraticEmitterLeft
@onready var right_emitter: DemocraticEmitter = $DemocraticEmitterRight
@onready var status_label: Label = $Control/StatusLabel


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("emit_left"):
		status_label.text = " EMITTED LEFT "
		left_emitter.emit_once()

	if Input.is_action_just_pressed("emit_right"):
		status_label.text = " EMITTED RIGHT "
		right_emitter.emit_once()
