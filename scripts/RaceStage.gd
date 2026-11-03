extends Control
signal finished(stars: int)

const ROAD := Color("#486a64")
var elapsed := 0.0
var duration := 22.0
var lane := 1
var stars := 0
var running := false
var driver_name := "角色"
var driver_color := Color("#ffca69")
var previous_star_checkpoint := -1
var hazards: Array = []

func start() -> void:
	elapsed = 0.0
	lane = 1
	stars = 0
	running = true
	previous_star_checkpoint = -1
	hazards.clear()
	queue_redraw()

func steer(direction: int) -> void:
	lane = clampi(lane + direction, 0, 2)
	queue_redraw()

func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	var checkpoint := int(elapsed * 1.7)
	if checkpoint != previous_star_checkpoint:
		previous_star_checkpoint = checkpoint
		if checkpoint % 4 == lane or checkpoint % 6 == 0:
			stars += 1
	if elapsed >= duration:
		running = false
		finished.emit(stars)
	queue_redraw()

func _draw() -> void:
	var area := Rect2(Vector2(size.x * 0.16, 8), Vector2(size.x * 0.68, maxf(100, size.y - 16)))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#bce7c4"), true)
	draw_rect(area, ROAD, true)
	for i in range(1, 3):
		var x: float = area.position.x + area.size.x * float(i) / 3.0
		for j in range(12):
			var y := fposmod(float(j) * 65.0 + elapsed * 160.0, area.size.y)
			draw_rect(Rect2(Vector2(x - 3, y + 8), Vector2(6, 32)), Color("#f6eeb2"))
	var car_width := minf(75.0, area.size.x / 5.2)
	var car_x: float = area.position.x + (float(lane) + 0.5) * area.size.x / 3.0
	var car_y: float = area.position.y + area.size.y * 0.76
	draw_rect(Rect2(Vector2(car_x - car_width * 0.5, car_y - 36), Vector2(car_width, 92)), driver_color, true)
	draw_rect(Rect2(Vector2(car_x - car_width * 0.36, car_y - 15), Vector2(car_width * 0.72, 34)), Color("#d9eef8"), true)
	for dx in [-car_width * 0.58, car_width * 0.58]:
		draw_rect(Rect2(Vector2(car_x + dx - 7, car_y - 21), Vector2(14, 22)), Color("#334e4b"))
		draw_rect(Rect2(Vector2(car_x + dx - 7, car_y + 29), Vector2(14, 22)), Color("#334e4b"))
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	draw_rect(Rect2(Vector2(20, 10), Vector2(size.x - 40, 15)), Color("#e9e9d7"))
	draw_rect(Rect2(Vector2(20, 10), Vector2((size.x - 40) * progress, 15)), Color("#f6bd54"))
