extends SceneTree
## Artwork/UX regression: five distinct biome backgrounds must be built offline,
## full-width, with perspective Pokemon positions, live particles, and no overflow.
const Scenery=preload("res://scripts/PokemonBattleScenery.gd")
const Arena=preload("res://scripts/PokemonBattleArena.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var expected={
        "幽靈":"moonforest","水":"lakeside","草":"forest",
        "火":"sunset","一般":"meadow","超能力":"meadow"
    }
    if Scenery.BIOMES.size()!=5:
        _fail("Five distinct natural battle environments must be supported")
        return
    for kind in expected:
        if Scenery.choose_biome([kind])!=expected[kind]:
            _fail("Incorrect automatically selected biome for "+kind)
            return
    for canvas in [Vector2i(1280,720),Vector2i(1024,600)]:
        root.size=canvas
        await process_frame
        var main=load("res://scenes/Main.tscn").instantiate()
        root.add_child(main)
        await process_frame
        await process_frame
        main._change_mode(4)
        await process_frame
        var battle=main.battle_view
        battle._choose(0)
        battle._choose(1) # Gengar: ghost forest.
        await process_frame
        if battle.battle_biome!="moonforest":
            _fail("Gengar should bring a moonlit forest")
            return
        if battle.arena_node==null or not battle.arena_node is Arena:
            _fail("Battle must use a perspective landscape arena instead of a flat HBox")
            return
        var stage=battle.arena_node
        if stage.landscape!="moonforest" or stage.scenery==null or stage.effects==null:
            _fail("Animated battle arena must contain layered scenery and spell overlay")
            return
        if stage.player_portrait==null or stage.opponent_portrait==null:
            _fail("Official Pokemon portraits must remain visible on the scenic battlefield")
            return
        var hero=stage.get_node("ForegroundPokemon")
        var rival=stage.get_node("DistantPokemon")
        if hero.anchor_top<=rival.anchor_top or hero.anchor_left>=rival.anchor_left:
            _fail("My Pokemon must stand closer and lower-left than the opponent")
            return
        if absf(stage.scenery.size.x-stage.size.x)>2.0:
            _fail("Scenery must fill the whole battle viewport")
            return
        if stage.get_global_rect().end.y>main.content_scroller.get_global_rect().end.y+3.0:
            _fail("Arena should fit above fixed speech bar on compact landscape")
            return
        battle.play_move(1)
        await process_frame
        if not battle.arena_node.effects.active:
            _fail("Attack should launch animated particles on the arena")
            return
        if not battle.arena_node.effects.element=="電":
            _fail("Pikachu's strong attack must trigger electric particles")
            return
        var effects=battle.arena_node.effects
        await create_timer(.82).timeout
        if not is_instance_valid(effects) or effects.active:
            _fail("Projectile should dissipate without lingering visual effects")
            return
        await create_timer(.3).timeout
        if battle.busy:
            _fail("The scenic overlay must not block the CPU counterattack")
            return
        # Switching enemy selects environment without changing user Pokemon.
        for pair in [[4,"forest"],[5,"lakeside"],[8,"sunset"],[2,"meadow"]]:
            battle._new_opponent()
            battle._choose(int(pair[0]))
            await process_frame
            if battle.battle_biome!=str(pair[1]) or battle.arena_node.landscape!=str(pair[1]):
                _fail("Biome did not switch for opponent "+str(pair[0]))
                return
            if battle.arena_node.effects.mouse_filter!=Control.MOUSE_FILTER_IGNORE:
                _fail("Visual effects must not intercept preschool attack button taps")
                return
        main.queue_free()
        await process_frame
    print("PASS: 5 layered offline battle biomes, stage perspective, glowing impacts and damage effects, English UI and unclipped landscape")
    quit(0)

func _fail(reason: String) -> void:
    push_error("BATTLE SCENERY FAILED: "+reason)
    quit(1)
