extends SceneTree

func _initialize() -> void:
    var scene := load("res://scenes/Main.tscn")
    if scene == null:
        push_error("Main scene could not load")
        quit(1)
        return
    var instance := scene.instantiate()
    if instance == null:
        push_error("Main scene could not instantiate")
        quit(1)
        return
    print("PASS: Main scene and GDScript loaded")
    instance.free()
    quit(0)
