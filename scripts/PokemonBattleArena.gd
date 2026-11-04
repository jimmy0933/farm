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

func play_impact(player_attacks: bool,move_type: String,damage: int,efficacy: float) -> void:
    if is_instance_valid(effects):
        effects.trigger(move_type,player_attacks,damage,efficacy)
    var shooter=player_portrait if player_attacks else opponent_portrait
    var target=opponent_portrait if player_attacks else player_portrait
    if is_instance_valid(shooter):
        shooter.pivot_offset=shooter.size*.5
        var jump=create_tween()
        jump.tween_property(shooter,"scale",Vector2(1.08,1.08),.13).set_trans(Tween.TRANS_BACK)
        jump.tween_property(shooter,"scale",Vector2.ONE,.2)
    if is_instance_valid(target):
        target.pivot_offset=target.size*.5
        var hit=create_tween()
        var tint=Color("#FCE5A9") if damage>0 else Color("#BBD5E9")
        hit.tween_property(target,"modulate",tint,.12)
        hit.tween_property(target,"modulate",Color.WHITE,.29)
