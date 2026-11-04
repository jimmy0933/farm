extends SceneTree
## New species integration: official artwork files, measurements, narration,
## independent scrollable Pokedex details, and both roles in the battle arena.
const Rules=preload("res://scripts/PokemonBattleRules.gd")
const EXPECTED={
    473:{"name":"象牙豬","height":2.5,"weight":291.0,"types":["冰","地面"],"moves":["冰礫","地震"]},
    167:{"name":"圓絲蛛","height":0.5,"weight":8.5,"types":["蟲","毒"],"moves":["毒針","蟲咬"]},
    1:{"name":"妙蛙種子","height":0.7,"weight":6.9,"types":["草","毒"],"moves":["藤鞭","飛葉快刀"]}
}

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var had_save=FileAccess.file_exists("user://pokemon_kids_progress.json")
    var saved=FileAccess.get_file_as_bytes("user://pokemon_kids_progress.json") if had_save else PackedByteArray()
    for screen in [Vector2i(1280,720),Vector2i(1024,600)]:
        root.size=screen
        await process_frame
        var game=load("res://scenes/Main.tscn").instantiate()
        root.add_child(game)
        await process_frame
        await process_frame
        if game.pokemon.size()!=15 or Rules.MOVES.size()!=15:
            _fail("The game should have 15 fully playable Pokemon")
            return
        for id in EXPECTED:
            var expected=EXPECTED[id]
            var index=-1
            for i in range(game.pokemon.size()):
                if int(game.pokemon[i]["id"])==id:
                    index=i
                    break
            if index==-1:
                _fail("Missing new Pokemon "+str(id))
                return
            var friend: Dictionary=game.pokemon[index]
            if str(friend["name"])!=str(expected["name"]) or friend["types"]!=expected["types"]:
                _fail("Name or type mismatch for Pokemon "+str(id))
                return
            if absf(float(friend["height"])-float(expected["height"]))>.001 or absf(float(friend["weight"])-float(expected["weight"]))>.001:
                _fail("Official height/weight mismatch for Pokemon "+str(id))
                return
            var moves=Rules.moves_for(id)
            if moves.size()!=2 or moves[0][0]!=expected["moves"][0] or moves[1][0]!=expected["moves"][1]:
                _fail("Species-specific battle move list mismatch for "+str(id))
                return
            for move in friend["moves"]:
                if not expected["moves"].has(str(move["name"])) or str(move["description"]).length()<8:
                    _fail("Voice move explanation missing for Pokemon "+str(id))
                    return
            var file="res://assets/pokemon/%d.png" % id
            if not ResourceLoader.exists(file):
                _fail("Official artwork was not packaged: "+file)
                return
            var texture=load(file)
            if not texture is Texture2D or texture.get_width()<100 or texture.get_height()<100:
                _fail("Pokemon artwork was not readable: "+file)
                return
            game._select_friend(index)
            await process_frame
            await process_frame
            if game.selected!=index or not game.last_speech.contains(str(friend["name"])):
                _fail("Selecting must announce the new Pokemon: "+str(id))
                return
            if game.pokemon_roster_scroll==null or game.pokemon_detail_scroll==null:
                _fail("New species must retain both independent scrollable Pokedex panels")
                return
            game._say_types()
            if not game.last_speech.contains("比較害怕"):
                _fail("Pokemon should narrate its weaknesses for "+str(id))
                return
            game._say_measurements()
            var weight_words="291" if id==473 else ("8.5" if id==167 else "6.9")
            if not game.last_speech.contains(weight_words):
                _fail("Pokemon height and weight speech lacks the official weight: "+str(id))
                return
            game._say_abilities()
            if game.last_speech.length()<20:
                _fail("Pokemon ability voice text is missing: "+str(id))
                return
            game._change_mode(4)
            await process_frame
            var battle=game.battle_view
            if battle.roster.size()!=15:
                _fail("Battle roster didn't update to 15 Pokemon")
                return
            battle._choose(index)
            battle._choose(0)
            await process_frame
            if battle.player_index!=index or battle.opponent_index!=0:
                _fail("New Pokemon cannot battle Pikachu: "+str(id))
                return
            battle.play_move(0)
            if battle.opponent_hp>=100:
                _fail("New Pokemon's battle attack did no damage: "+str(id))
                return
            await create_timer(1.05).timeout
            # Pikachu's electric move is harmless to ground-type Mamoswine.
            # Require a completed AI turn, not always nonzero damage.
            if battle.busy:
                _fail("Computer did not finish its counterattack: "+str(id))
                return
            # Player opponent still has both HP bars when testing reverse match.
            game._change_mode(0)
            await process_frame
        game.queue_free()
        await process_frame
    if had_save:
        var restored=FileAccess.open("user://pokemon_kids_progress.json",FileAccess.WRITE)
        restored.store_buffer(saved)
        restored.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path("user://pokemon_kids_progress.json"))
    print("PASS: Mamoswine Spinarak Bulbasaur official artwork, audio, Pokedex, 15-friend scroll and battle at two phone sizes")
    quit(0)

func _fail(message: String) -> void:
    push_error("NEW POKEMON FAILED: "+message)
    quit(1)
