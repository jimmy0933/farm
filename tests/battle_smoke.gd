extends SceneTree
## Battle gameplay, controls, subtype effectiveness, storage and landscape
## layout regressions for the 4-year-old voice-first Pokemon app.
const Rules=preload("res://scripts/PokemonBattleRules.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var saved_bytes=PackedByteArray()
    var existing=FileAccess.file_exists("user://pokemon_kids_progress.json")
    if existing:
        saved_bytes=FileAccess.get_file_as_bytes("user://pokemon_kids_progress.json")
    if Rules.MOVES.size()!=12 or Rules.MAX_HP!=100:
        _fail("All twelve Pokemon need two attack choices and 100 HP")
        return
    if Rules.effectiveness("電",["水"])!=2.0 or Rules.effectiveness("電",["地面"])!=0.0:
        _fail("Weaknesses and immunities need correct type chart values")
        return
    if Rules.effectiveness("幽靈",["一般"])!=0.0 or Rules.effectiveness("蟲",["草","超能力"])!=4.0:
        _fail("Pokemon immunities or dual-type vulnerabilities are incorrect")
        return
    var rng=RandomNumberGenerator.new()
    rng.seed=42
    var pikachu={"id":25,"types":["電"]}
    var blastoise={"id":133,"types":["一般"]}
    for i in range(50):
        var normal=Rules.strike(pikachu,blastoise,0,rng)
        var heavy=Rules.strike(pikachu,blastoise,1,rng)
        if normal["damage"]<12 or normal["damage"]>20:
            _fail("Standard attack damage should be between 12 and 20")
            return
        if heavy["damage"]<20 or heavy["damage"]>30:
            _fail("Strong attack must produce a randomized 20-30 base damage")
            return
    if Rules.clamp_health(4,30)!=0 or Rules.clamp_health(99,0)!=99:
        _fail("HP must stop at zero and never go negative")
        return
    for screen_size in [Vector2i(1280,720),Vector2i(1024,600)]:
        root.size=screen_size
        await process_frame
        var main=load("res://scenes/Main.tscn").instantiate()
        root.add_child(main)
        await process_frame
        await process_frame
        var backup_hearts=main.hearts.duplicate(true)
        var backup_wins=main.battle_wins.duplicate(true)
        var backup_discovered=main.discovered.duplicate(true)
        var old_language=main.button_language
        if main.pokemon.size()!=12 or main.MODES.size()!=6:
            _fail("All twelve Pokemon and six modes must be present")
            return
        # Every pairing must have an attack that can deal damage.
        # In particular, Ghost-type immunity used to trap Eevee/Aipom matches.
        for attacker in main.pokemon:
            for defender in main.pokemon:
                if attacker["id"]==defender["id"]:
                    continue
                var viable=false
                for move in Rules.moves_for(int(attacker["id"])):
                    if Rules.effectiveness(str(move[1]),defender["types"])>0.0:
                        viable=true
                if not viable:
                    _fail("Unwinnable matchup: "+str(attacker["name"])+" vs "+str(defender["name"]))
                    return
        # The speech footer stays on screen even for tall Pokedex details.
        var footer=_named(main,"VoiceFooter")
        var content=main.content_scroller
        if footer==null or content==null:
            _fail("Fixed voice footer and middle scroll container are missing")
            return
        if footer.get_global_rect().end.y>float(screen_size.y)+1.0:
            _fail("Voice buttons are clipped below the display in Pokedex")
            return
        if content.get_global_rect().end.y>footer.get_global_rect().position.y+2.0:
            _fail("Scroll content overlays bottom playback controls")
            return
        if content.get_v_scroll_bar().max_value<=content.size.y:
            _fail("Long Pokedex details should be scrollable on a compact phone")
            return

        main._change_mode(5)
        await process_frame
        main._change_button_language("en")
        await process_frame
        if main.button_language!="en" or not _button_contains(main,"Settings"):
            _fail("English button switch must update main mode labels")
            return
        if not _button_contains(main,"Replay") or main._translated_button("🔊 電光一閃")!="🔊 Quick Attack":
            _fail("English must cover playback and dynamically named move buttons")
            return
        var settings=JSON.parse_string(FileAccess.get_file_as_string("user://pokemon_kids_progress.json"))
        if settings.get("button_language","")!="en":
            _fail("English button choice must survive restart")
            return

        main._change_mode(4)
        await process_frame
        var battle=main.battle_view
        if battle==null or battle.roster.size()!=12:
            _fail("Battle mode must offer all existing Pokemon")
            return
        var picker=_named(battle,"BattleSelectionScroll")
        if picker==null:
            _fail("Player selection requires a scrollable, tappable portrait grid")
            return
        battle._choose(0)
        await process_frame
        if battle.player_index!=0 or battle.opponent_index!=-1:
            _fail("Selecting my Pokemon must advance to opponent selection")
            return
        battle._choose(1)
        await process_frame
        if battle.opponent_index!=1 or battle.player_hp!=100 or battle.opponent_hp!=100:
            _fail("Chosen opponent needs an independent full HP bar")
            return
        var my_bar=_named(battle,"PlayerHealth")
        var their_bar=_named(battle,"OpponentHealth")
        if my_bar==null or their_bar==null or my_bar.value!=100 or their_bar.value!=100:
            _fail("Both live health bars must start at 100")
            return
        if battle.move_buttons.size()!=2 or not battle.move_buttons[0].text.contains("Quick Attack"):
            _fail("English battle needs two large translated move buttons")
            return
        battle.play_move(1)
        if not battle.busy or battle.opponent_hp>=100:
            _fail("Attacking must subtract damage and wait for CPU reply")
            return
        var hp_after_hit=battle.opponent_hp
        battle.play_move(1)
        if battle.opponent_hp!=hp_after_hit:
            _fail("Fast double tapping while the CPU acts must be ignored")
            return
        await create_timer(1.2).timeout
        await process_frame
        if battle.busy or battle.player_hp>=100:
            _fail("Computer must counterattack automatically after player's move")
            return
        if battle.player_strong_rest!=1 or not battle.move_buttons[1].disabled:
            _fail("Strong attack must rest for one turn")
            return
        # Normal-type Quick Attack cannot hit Ghost-type Gengar.
        # Switch to Eevee to test an ordinary finishing blow.
        battle._new_opponent()
        battle._choose(2)
        battle.opponent_hp=1
        var wins_before=int(main.battle_wins.get(str(main.pokemon[0]["id"]),0))
        battle.play_move(0)
        await process_frame
        if not battle.finished or battle.opponent_hp!=0 or int(main.battle_wins.get(str(main.pokemon[0]["id"]),0))!=wins_before+1:
            _fail("Fainting opponent must finish battle and persist one victory")
            return
        battle.play_move(0)
        if int(main.battle_wins.get(str(main.pokemon[0]["id"]),0))!=wins_before+1:
            _fail("Finished battles must never award repeated victories")
            return
        battle._start()
        battle.player_hp=1
        battle._cpu_turn()
        if not battle.finished or battle.player_hp!=0:
            _fail("Opponent victory must also stop at zero HP")
            return
        battle._new_opponent()
        if battle.opponent_index!=-1 or battle.player_index!=0:
            _fail("Change opponent must preserve my selected Pokemon")
            return
        main._change_mode(0)
        await process_frame
        if main.last_speech.is_empty():
            _fail("The voice-first app must retain Chinese narration")
            return
        main.hearts=backup_hearts
        main.battle_wins=backup_wins
        main.discovered=backup_discovered
        main.button_language=old_language
        main._save_progress()
        main.queue_free()
        await process_frame
    if existing:
        var restore=FileAccess.open("user://pokemon_kids_progress.json",FileAccess.WRITE)
        restore.store_buffer(saved_bytes)
        restore.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path("user://pokemon_kids_progress.json"))
    print("PASS: 12 Pokemon battles, damage types, two move buttons, automatic counters, 100 HP knockout, voice, English settings and unclipped bottom")
    quit(0)

func _named(node: Node, wanted: String) -> Node:
    if node.name==wanted:
        return node
    for child in node.get_children():
        var found=_named(child,wanted)
        if found!=null:
            return found
    return null

func _button_contains(node: Node, phrase: String) -> bool:
    if node is Button and str(node.text).contains(phrase):
        return true
    for child in node.get_children():
        if _button_contains(child,phrase):
            return true
    return false

func _fail(message: String) -> void:
    push_error("POKEMON BATTLE/SETTINGS FAILED: "+message)
    quit(1)
