extends Control
var brush_color: Color = Color("#f2878c")
var lines: Array[Dictionary] = []
var drawing := false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			drawing = event.pressed
			if drawing:
				lines.append({"color": brush_color, "points": PackedVector2Array([event.position])})
				queue_redraw()
	elif event is InputEventMouseMotion and drawing and not lines.is_empty():
		lines[-1]["points"].append(event.position)
		queue_redraw()

func clear_board() -> void:
	lines.clear()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#fffdf2"), true)
	for line_data in lines:
		var points: PackedVector2Array = line_data["points"]
		for i in range(1, points.size()):
			draw_line(points[i - 1], points[i], line_data["color"], 8.0, true)
