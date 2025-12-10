extends Node2D


# --- References ---

@onready var height_label: Label = %HeightLabel
@onready var box_label: Label = %BoxLabel
@onready var player: BoxPickingPlayer = $Player

@onready var floor_height: float = $StaticBody2D.position.y


# --- Logics ---

## Update labels
func update_label() -> void:
	self.height_label.text = "Height: %.2f" % -(self.player.position.y - self.floor_height + 14.7)
	self.box_label.text = "Box: %s" % (bool(self.player.box != null))
	# ^ USE SIGNAL FOR BOX DON'T DO THIS IN REAL GAME WHEN OPITIMIZING


# --- Drivers ---

func _process(delta: float) -> void:
	self.update_label()
