extends SceneTree

func _initialize() -> void:
    call_deferred("_run_smoke")

func _run_smoke() -> void:
    var resource = load("res://scenes/Main.tscn")
    if resource == null:
        push_error("Main scene could not load")
        quit(1)
        return
    var instance = resource.instantiate()
    if instance == null:
        push_error("Main scene could not instantiate")
        quit(1)
        return
    get_root().add_child(instance)
    await process_frame
    if instance.pokemon.size() != 15:
        push_error("Expected fifteen Pokémon on the main screen")
        quit(1)
        return
    for new_id in [9, 54, 190, 473, 167, 1]:
        var found := false
        for index in range(instance.pokemon.size()):
            if int(instance.pokemon[index]["id"]) == new_id:
                instance._select_friend(index)
                instance._say_types()
                instance._say_measurements()
                instance._say_abilities()
                instance._say_move(str(instance.pokemon[index]["moves"][0]["name"]), str(instance.pokemon[index]["moves"][0]["description"]))
                found = true
                break
        if not found:
            push_error("Missing new Pokemon: %d" % new_id)
            quit(1)
            return
    instance._select_friend(0)
    instance._say_types()
    instance._say_measurements()
    instance._say_abilities()
    for tab in range(6):
        instance._change_mode(tab)
        await process_frame
    instance._next_question()
    instance._change_mode(1)
    instance._answer(instance.quiz_target)
    instance._change_mode(2)
    instance._care_play("一起玩耍")
    instance._change_mode(3)
    await process_frame
    print("PASS: Fifteen Pokémon, all six screens, voice controls and interactions")
    quit(0)
