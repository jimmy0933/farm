extends Control
## Composition of one battle landscape, foreground Pokemon, and spell overlay.
## Sprite anchors use proportions, so both 16:9 and compact phones are safe.
const Scenery=preload("res://scripts/PokemonBattleScenery.gd")
const Effects=preload("res://scripts/PokemonBattleEffects.gd")
const INK=Color("#304455")

var hero: Dictionary={}
var enemy: Dictionary={}
var landscape: String="meadow"
var scene_variant: int=0
var player_portrait: Control
var opponent_portrait: Control
var scenery: Control
var effects: Control

func configure(player: Dictionary,opponent: Dictionary,biome: String,variant: int=0) -> void:
    hero=player
    enemy=opponent
    landscape=biome
    scene_variant=variant

func _ready() -> void:
    name="BattleArena"
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    clip_contents=true
    size_flags_horizontal=Control.SIZE_EXPAND_FILL
    size_flags_vertical=Control.SIZE_SHRINK_BEGIN
    scenery=Scenery.new()
    scenery.name="BattleScenery"
    scenery.setup(landscape,scene_variant)
    scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(scenery)
    _create_characters()
    effects=Effects.new()
    effects.name="BattleEffects"
    add_child(effects)
    effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _make_holder(node_name: String,left: float,top: float,right: float,bottom: float) -> Control:
    var holder=Control.new()
    holder.name=node_name
    holder.anchor_left=left
    holder.anchor_top=top
    holder.anchor_right=right
    holder.anchor_bottom=bottom
    holder.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(holder)
    return holder

func _picture(entry: Dictionary,holder: Control) -> Control:
    var file="res://assets/pokemon/%d.png" % int(entry["id"])
    var art: Control
    if ResourceLoader.exists(file):
        var img=TextureRect.new()
        img.texture=load(file)
        img.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
        img.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        art=img
    else:
        var icon=Label.new()
        icon.text=str(entry.get("emoji","🌟"))
        icon.add_theme_font_size_override("font_size",72)
        icon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        icon.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
        art=icon
    art.mouse_filter=Control.MOUSE_FILTER_IGNORE
    holder.add_child(art)
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    return art

func _create_characters() -> void:
    # Perspective: larger near-side Pokemon in left foreground, smaller enemy
    # on a raised, distant mound. Ground ellipses are drawn by Scenery.
    var player_holder=_make_holder("ForegroundPokemon",.075,.35,.445,.91)
    var opponent_holder=_make_holder("DistantPokemon",.605,.10,.885,.66)
    player_portrait=_picture(hero,player_holder)
    opponent_portrait=_picture(enemy,opponent_holder)
    # Tiny ambient accents around the two platforms.
    var star=Label.new()
    star.text="✦"
    star.add_theme_color_override("font_color",Color("#FFFFFF",.72))
    star.add_theme_font_size_override("font_size",19)
    star.anchor_left=.46
    star.anchor_top=.17
    star.anchor_right=.53
    star.anchor_bottom=.28
    star.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    star.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(star)

var fallen_player: bool=false
var fallen_opponent: bool=false


func play_attack_sequence(player_attacks: bool,move_type: String,damage: int,efficacy: float,strong_move: bool=false,fast_test: bool=false) -> void:
    if not is_instance_valid(effects):
        return
    effects.trigger(move_type,player_attacks,damage,efficacy,strong_move)
    var total=effects.duration
    if fast_test:
        effects.duration=.10
        total=.10
    var shooter=player_portrait if player_attacks else opponent_portrait
    var target=opponent_portrait if player_attacks else player_portrait
    if is_instance_valid(shooter):
        shooter.pivot_offset=shooter.size*.5
        var charge=create_tween()
        charge.tween_property(shooter,"scale",Vector2(1.16,1.16),total*.23).set_trans(Tween.TRANS_SINE)
        charge.tween_property(shooter,"scale",Vector2(1.05,1.05),total*.45)
        charge.tween_property(shooter,"scale",Vector2.ONE,total*.32)
    if is_instance_valid(target):
        target.pivot_offset=target.size*.5
        var hit=create_tween()
        hit.tween_interval(total*.70)
        var tint=Color("#FFE5AE") if damage>0 else Color("#C8DAEE")
        hit.tween_property(target,"modulate",tint,total*.10)
        hit.tween_property(target,"modulate",Color.WHITE,total*.20)
    await get_tree().create_timer(total+.03).timeout


func play_fall_sequence(is_player: bool,fast_test: bool=false) -> void:
    var target=player_portrait if is_player else opponent_portrait
    if not is_instance_valid(target):
        return
    if is_player:
        fallen_player=true
    else:
        fallen_opponent=true
    target.pivot_offset=target.size*.55
    var fall_seconds=.22 if fast_test else .90
    var angle=-72.0 if is_player else 72.0
    var dust=Label.new()
    dust.name="KnockoutDust"
    dust.text="☁️  ✨  ⭐  ✨"
    dust.add_theme_font_size_override("font_size",29)
    dust.add_theme_color_override("font_color",Color("#FBE7B7"))
    dust.mouse_filter=Control.MOUSE_FILTER_IGNORE
    var midpoint=target.get_global_rect().get_center()-get_global_rect().position
    dust.position=midpoint+Vector2(-74,20)
    add_child(dust)
    var stars=Label.new()
    stars.name="KnockoutStars"
    stars.text="⭐  💫  ⭐"
    stars.add_theme_font_size_override("font_size",34)
    stars.mouse_filter=Control.MOUSE_FILTER_IGNORE
    stars.position=midpoint+Vector2(-68,-49)
    add_child(stars)
    var motion=create_tween()
    motion.set_parallel(true)
    motion.tween_property(target,"rotation_degrees",angle,fall_seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    motion.tween_property(target,"position:y",target.position.y+24.0,fall_seconds)
    motion.tween_property(target,"scale",Vector2(.88,.77),fall_seconds)
    motion.tween_property(target,"modulate:a",.72,fall_seconds)
    motion.tween_property(stars,"position:y",stars.position.y-26.0,fall_seconds)
    motion.tween_property(stars,"modulate:a",.2,fall_seconds)
    motion.tween_property(dust,"modulate:a",0.0,fall_seconds)
    await motion.finished
    if is_instance_valid(stars):
        stars.queue_free()
    if is_instance_valid(dust):
        dust.queue_free()


func apply_fallen_pose(is_player: bool) -> void:
    # Called after the result controls rebuild the arena; keep the losing
    # Pokemon lying down instead of popping upright after the KO animation.
    var target=player_portrait if is_player else opponent_portrait
    if not is_instance_valid(target):
        return
    target.pivot_offset=target.size*.55
    target.rotation_degrees=-72.0 if is_player else 72.0
    target.position.y+=24.0
    target.scale=Vector2(.88,.77)
    target.modulate.a=.72
    if is_player:
        fallen_player=true
    else:
        fallen_opponent=true
