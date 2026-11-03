extends Control
## Simple editable placeholder art. Original APK art lives in compiled scripts.
var creature_color: Color = Color("#f3cf88")
var species_key: String = ""

func configure(record: Dictionary) -> void:
	creature_color = Color(str(record.get("color", "#f3cf88")))
	species_key = str(record.get("id", ""))
	custom_minimum_size = Vector2(108, 105)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius: float = minf(size.x, size.y) * 0.34
	var dark := creature_color.darkened(0.35)
	var ear_offset := radius * 0.57
	var mod_value := absi(species_key.hash()) % 3
	if mod_value == 0:
		draw_colored_polygon(PackedVector2Array([center + Vector2(-radius * 0.8, -radius * 0.42), center + Vector2(-radius * 0.64, -radius * 1.42), center + Vector2(-radius * 0.2, -radius * 0.7)]), creature_color)
		draw_colored_polygon(PackedVector2Array([center + Vector2(radius * 0.8, -radius * 0.42), center + Vector2(radius * 0.64, -radius * 1.42), center + Vector2(radius * 0.2, -radius * 0.7)]), creature_color)
	elif mod_value == 1:
		draw_circle(center + Vector2(-ear_offset, -radius * 0.6), radius * 0.34, creature_color)
		draw_circle(center + Vector2(ear_offset, -radius * 0.6), radius * 0.34, creature_color)
	else:
		draw_circle(center + Vector2(-ear_offset, -radius * 0.35), radius * 0.3, creature_color)
		draw_circle(center + Vector2(ear_offset, -radius * 0.35), radius * 0.3, creature_color)
	draw_circle(center, radius + 3, Color(1, 1, 1, 0.75))
	draw_circle(center, radius, creature_color)
	var eye_r := radius * 0.115
	for sign in [-1, 1]:
		var p := center + Vector2(sign * radius * 0.38, -radius * 0.09)
		draw_circle(p, eye_r, dark)
		draw_circle(p + Vector2(-2, -2), eye_r * 0.3, Color.WHITE)
	draw_arc(center + Vector2(0, radius * 0.15), radius * 0.28, 0.22, PI - 0.22, 24, dark, 2.7, true)
	draw_circle(center + Vector2(0, radius * 0.22), radius * 0.07, dark)
