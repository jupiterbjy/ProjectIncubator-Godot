extends Node3D


# --- References ---

## Used to store contact reports
@onready var report_container: VBoxContainer = %ReportContainer

## Multi-Collision body we'll play with
@onready var body: RigidBody3D = $SomeBody


# --- Drivers ---

## Add new hit report for incoming contact message
func _on_some_body_contact_report(msg: String) -> void:
	self.report_container.add_child(HitReport.create_instance(msg))


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("drop"):
		# reset position
		self.body.position = Vector3(0, 1, 0)
