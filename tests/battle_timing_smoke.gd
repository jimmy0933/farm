extends SceneTree
## Regression: enemy can NEVER attack before the player's spoken move ends.
## Real-duration animations must land before HP changes, and KO must tumble
## before victory appears. Uses controlled TTS completion in headless CI.
const Narrator=preload("res://tests/BattleNarratorGate.gd")
const Effects=preload("res://scripts/PokemonBattleEffects.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size=Vector2i(1280,720)
    var had_save=FileAccess.file_exists("user://pokemon_kids_progress.json")
    var backed_up=FileAccess.get_file_as_bytes("user://pokemon_kids_progress.json") if had_save else PackedByteArray()
    var main=load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    await process_frame
    main._change_mode(4)
    await process_frame
    var battle=main.battle_view
    battle._choose(0)
    battle._choose(2) # Pikachu vs Eevee; no immunity shortcuts
    await process_frame
    if Effects.NORMAL_DURATION<1.3 or Effects.STRONG_DURATION<1.7:
        _fail("Charge, projectile and impact are still too fast")
        return
    var fake=Narrator.new()
    root.add_child(fake)
    battle.speech_host=fake
    battle.play_move(1)
    await create_timer(.24).timeout
    if fake.calls!=1 or not battle.busy or battle.opponent_hp!=100 or battle.player_hp!=100:
        _fail("Player/CPU health must stay full while the first speech is unfinished")
        return
    if battle.arena_node.effects.active:
        _fail("Move cannot begin flying before player narration completes")
        return
    if battle.move_buttons.is_empty() or not battle.move_buttons[0].disabled:
        _fail("Children must not double tap while narration is running")
        return
    fake.narration_released.emit()
    await create_timer(.20).timeout
    if not battle.arena_node.effects.active or not battle.arena_node.effects.strong_move:
        _fail("Strong attack should show its longer charge/flying effects after speech")
        return
    if battle.opponent_hp!=100:
        _fail("Damage should not apply until after the visual attack hits")
        return
    var max_wait=0
    while fake.calls<2 and max_wait<65:
        await create_timer(.08).timeout
        max_wait+=1
    if fake.calls!=2 or battle.player_hp!=100:
        _fail("Opponent's second narration must start only after player effect and HP drain")
        return
    if battle.opponent_hp>=100:
        _fail("Player HP damage must be applied after player spell")
        return
    await create_timer(.22).timeout
    if battle.player_hp!=100:
        _fail("CPU attack cannot land while CPU speech is unfinished")
        return
    fake.narration_released.emit()
    await create_timer(2.7).timeout
    if battle.busy or battle.player_hp>=100:
        _fail("Opponent reply should finally deal damage and return control to player")
        return
    battle.opponent_hp=1
    var before_wins=int(main.battle_wins.get(str(main.pokemon[0]["id"]),0))
    battle.play_move(0)
    await create_timer(.18).timeout
    if fake.calls!=3 or battle.finished or battle.opponent_hp!=1:
        _fail("Knockout should not start until the finishing move is spoken")
        return
    fake.narration_released.emit()
    await create_timer(2.05).timeout
    if not battle.arena_node.fallen_opponent or battle.finished:
        _fail("Opponent should visibly tumble BEFORE victory result is shown")
        return
    await create_timer(1.20).timeout
    if not battle.finished or battle.opponent_hp!=0 or not battle.arena_node.fallen_opponent:
        _fail("Victory should follow completed KO animation with fallen character visible")
        return
    if absf(battle.arena_node.opponent_portrait.rotation_degrees)<60.0:
        _fail("Losing Pokemon should remain lying down on victory screen")
        return
    if int(main.battle_wins.get(str(main.pokemon[0]["id"]),0))!=before_wins+1:
        _fail("KO victory must award exactly one win after falling")
        return

    # Changing opponent while speaking invalidates an old asynchronous turn.
    battle._start()
    battle.play_move(0)
    await create_timer(.15).timeout
    if fake.calls!=4:
        _fail("Narrator gate missing after rematch")
        return
    battle._new_opponent()
    fake.narration_released.emit()
    await create_timer(.20).timeout
    if battle.opponent_index!=-1 or battle.player_hp!=100:
        _fail("Abandoned narration must not resurrect a stale attack")
        return

    main.queue_free()
    fake.queue_free()
    await process_frame
    if had_save:
        var restore=FileAccess.open("user://pokemon_kids_progress.json",FileAccess.WRITE)
        restore.store_buffer(backed_up)
        restore.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path("user://pokemon_kids_progress.json"))
    print("PASS: real TTS completion gate, slow staged attacks, delayed HP loss, CPU reply and gentle persistent knockout fall")
    quit(0)

func _fail(message: String) -> void:
    push_error("BATTLE TIMING FAILED: "+message)
    quit(1)
