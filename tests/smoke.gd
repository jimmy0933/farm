extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		push_error("Main scene failed to load")
		quit(1)
		return
	var main = scene.instantiate()
	if main == null:
		push_error("Main scene failed to instantiate")
		quit(1)
		return
	main.free()
	print("Farm scripts and Main scene parsed OK")
	quit(0)
