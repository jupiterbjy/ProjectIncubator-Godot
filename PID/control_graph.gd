class_name ControlGraph
extends ColorRect


# --- Exports ---

@export var line_color := Color.RED
@export var zero_line_color := Color.WEB_GRAY

@export var text: String = "HINA"

@export var max_points: int = 256

@export var max_val: float = 1.0
@export var min_val: float = -1.0

@export var font: Font = null


# --- Attributes ---

var points: Array[float]


# --- Methods ---

func add_point(val: float) -> void:
	if len(self.points) >= self.max_points:
		self.points.pop_front()

	self.points.append(val)
	self.queue_redraw()


func reset() -> void:
	points.clear()
	self.queue_redraw()


# --- Handlers ---

func _ready() -> void:
	if not self.font:
		self.font = self.get_theme_default_font()

	self.queue_redraw()


func _draw() -> void:
	var rect_size := self.get_rect().size

	var val_range := self.max_val - self.min_val
	var zero_pos := (-self.min_val / val_range) * rect_size.y

	# draw zero indicator line
	self.draw_line(
		Vector2(0, zero_pos),
		Vector2(rect_size.x, zero_pos),
		Color.BLACK,
	)

	# plot
	for idx: int in range(len(self.points) - 1):
		self.draw_line(
			Vector2(
				rect_size.x * float(idx) / float(len(self.points)),
				rect_size.y * clampf(self.points[idx] - self.min_val, 0, val_range) / val_range
			),
			Vector2(
				rect_size.x * float(idx + 1) / float(len(self.points)),
				rect_size.y * clampf(self.points[idx + 1] - self.min_val, 0, val_range) / val_range
			),
			self.line_color,
			1.0
		)

	# title
	self.font.draw_string(
		self.get_canvas_item(),
		Vector2(0, 24.0),
		self.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		rect_size.x * 0.5,
		32,
		Color.BLACK,
	)

	# upper lim val
	self.font.draw_string(
		self.get_canvas_item(),
		Vector2(rect_size.x * 0.5, 24.0),
		"%5.2f" % self.max_val,
		HORIZONTAL_ALIGNMENT_RIGHT,
		rect_size.x * 0.5,
		32,
		Color.BLACK,
	)

	# lower lim val
	self.font.draw_string(
		self.get_canvas_item(),
		Vector2(rect_size.x * 0.5, rect_size.y - 2.0),
		"%5.2f" % self.min_val,
		HORIZONTAL_ALIGNMENT_RIGHT,
		rect_size.x * 0.5,
		32,
		Color.BLACK,
	)

	# latest val
	self.font.draw_string(
		self.get_canvas_item(),
		Vector2(0.0, rect_size.y - 2.0),
		"%5.2f" % (self.points[-1] if self.points else 0.0),
		HORIZONTAL_ALIGNMENT_LEFT,
		rect_size.x * 0.5,
		32,
		self.line_color,
	)
