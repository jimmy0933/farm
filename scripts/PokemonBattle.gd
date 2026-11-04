extends PanelContainer
## One-on-one, turn-based Pokemon battle. All animation and state changes
## happen on the main scene tree and are blocked while the CPU is replying.
signal say_requested(message: String)
signal leave_requested
signal win_recorded(index: int)

const Rules=preload("res://scripts/PokemonBattleRules.gd")
const Scenery=preload("res://scripts/PokemonBattleScenery.gd")
const Arena=preload("res://scripts/PokemonBattleArena.gd")
const INK=Color("#29445B")
const LIGHT=Color("#FFFFFF")
const SOFT=Color("#EFF8FC")

var roster: Array=[]
var english_buttons: bool=false
var player_index: int=-1
var opponent_index: int=-1
var player_hp: int=Rules.MAX_HP
var opponent_hp: int=Rules.MAX_HP
var player_strong_rest: int=0
var opponent_strong_rest: int=0
var busy: bool=false
var finished: bool=false
var last_message: String=""
var last_damage: int=0
var last_effect: String=""
var player_portrait: Control
var opponent_portrait: Control
var arena_node: Control
var battle_biome: String="meadow"
var scene_variant: int=0
var move_buttons: Array=[]
var rng:=RandomNumberGenerator.new()

func configure(mons: Array, english: bool=false) -> void:
    roster=mons
    english_buttons=english
    rng.randomize()

func _ready() -> void:
    size_flags_horizontal=Control.SIZE_EXPAND_FILL
    size_flags_vertical=Control.SIZE_EXPAND_FILL
    var skin=StyleBoxFlat.new()
    skin.bg_color=LIGHT
    skin.set_corner_radius_all(22)
    skin.content_margin_left=15
    skin.content_margin_right=15
    skin.content_margin_top=10
    skin.content_margin_bottom=10
    add_theme_stylebox_override("panel",skin)
    _render()

func _button(zh: String, en: String, tint: Color=Color("#E2F5E9")) -> Button:
    var btn=Button.new()
    btn.text=en if english_buttons else zh
    btn.custom_minimum_size=Vector2(0,54)
    btn.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    btn.focus_mode=Control.FOCUS_NONE
    btn.add_theme_font_size_override("font_size",20)
    btn.add_theme_color_override("font_color",INK)
    btn.add_theme_color_override("font_hover_color",INK)
    btn.add_theme_color_override("font_pressed_color",INK)
    var base=StyleBoxFlat.new()
    base.bg_color=tint
    base.set_corner_radius_all(16)
    base.border_color=Color("#FFFFFF",.92)
    base.set_border_width_all(2)
    base.shadow_color=Color("#304F64",.19)
    base.shadow_size=5
    base.shadow_offset=Vector2(1,3)
    base.content_margin_left=9
    base.content_margin_right=9
    base.content_margin_top=7
    base.content_margin_bottom=7
    btn.add_theme_stylebox_override("normal",base)
    var hover: StyleBoxFlat=base.duplicate()
    hover.bg_color=tint.lightened(0.06)
    btn.add_theme_stylebox_override("hover",hover)
    var down: StyleBoxFlat=base.duplicate()
    down.bg_color=tint.darkened(0.09)
    btn.add_theme_stylebox_override("pressed",down)
    btn.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
    return btn

func _text(value: String, size: int=22, centered: bool=false) -> Label:
    var lab=Label.new()
    lab.text=value
    lab.add_theme_font_size_override("font_size",size)
    lab.add_theme_color_override("font_color",INK)
    lab.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
    lab.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    lab.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    lab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    return lab

func _portrait(index: int, min_size: Vector2=Vector2(160,145)) -> Control:
    var m: Dictionary=roster[index]
    var art_path="res://assets/pokemon/%d.png" % int(m["id"])
    if ResourceLoader.exists(art_path):
        var pic=TextureRect.new()
        pic.texture=load(art_path)
        pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
        pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        pic.custom_minimum_size=min_size
        pic.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        pic.mouse_filter=Control.MOUSE_FILTER_IGNORE
        return pic
    var fallback=_text(str(m["emoji"]),75,true)
    fallback.custom_minimum_size=min_size
    fallback.mouse_filter=Control.MOUSE_FILTER_IGNORE
    return fallback

func _clear() -> VBoxContainer:
    for c in get_children():
        remove_child(c)
        c.queue_free()
    var root=VBoxContainer.new()
    root.add_theme_constant_override("separation",7)
    root.size_flags_vertical=Control.SIZE_EXPAND_FILL
    add_child(root)
    return root

func _render() -> void:
    if roster.is_empty():
        return
    if player_index<0 or opponent_index<0:
        _picker()
    else:
        _battle()

func _picker() -> void:
    var root=_clear()
    var selecting_player=player_index<0
    var title="⚔️ 選我的寶可夢" if selecting_player else "🎯 選電腦對手"
    root.add_child(_text(title,27,true))
    root.add_child(_text("👆 點圖片就能選！" if selecting_player else "👆 挑一位對手，也可以按 🎲",18,true))
    var buttons=HBoxContainer.new()
    buttons.add_theme_constant_override("separation",9)
    root.add_child(buttons)
    if not selecting_player:
        var random_button=_button("🎲 隨機對手","🎲 Random",Color("#FFF0C9"))
        random_button.pressed.connect(_choose_random_opponent)
        buttons.add_child(random_button)
        var back=_button("◀ 重選自己","◀ My Pokémon",Color("#E6EBF8"))
        back.pressed.connect(_back_to_player)
        buttons.add_child(back)
    var list=ScrollContainer.new()
    list.name="BattleSelectionScroll"
    list.custom_minimum_size.y=300
    list.size_flags_vertical=Control.SIZE_EXPAND_FILL
    list.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(list)
    var grid=GridContainer.new()
    grid.name="PokemonChoiceGrid"
    grid.columns=6 if get_viewport_rect().size.x>=1100.0 else 4
    grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation",10)
    grid.add_theme_constant_override("v_separation",8)
    list.add_child(grid)
    for i in range(roster.size()):
        if not selecting_player and i==player_index:
            continue
        var m: Dictionary=roster[i]
        var card=_button("", "",Color(str(m["color"])).lightened(.22))
        card.name="Choose_%d" % int(m["id"])
        card.custom_minimum_size=Vector2(143,156)
        grid.add_child(card)
        var inner=VBoxContainer.new()
        inner.mouse_filter=Control.MOUSE_FILTER_IGNORE
        inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        inner.offset_left=4
        inner.offset_right=-4
        inner.offset_top=3
        inner.offset_bottom=-2
        card.add_child(inner)
        inner.add_child(_portrait(i,Vector2(120,113)))
        var nickname=_text(str(m["name"]),18,true)
        nickname.mouse_filter=Control.MOUSE_FILTER_IGNORE
        inner.add_child(nickname)
        card.pressed.connect(_choose.bind(i))
    var exit=_button("🏠 回圖鑑","🏠 Back",Color("#E6EEF5"))
    exit.custom_minimum_size.y=43
    exit.pressed.connect(func(): leave_requested.emit())
    root.add_child(exit)

func _choose(index: int) -> void:
    if index<0 or index>=roster.size():
        return
    if player_index<0:
        player_index=index
        say_requested.emit("選好了！%s要出場囉。再選一位電腦對手！" % str(roster[index]["name"]))
        _render()
    elif index!=player_index:
        opponent_index=index
        _start()

func _back_to_player() -> void:
    player_index=-1
    opponent_index=-1
    _render()

func _choose_random_opponent() -> void:
    if player_index<0 or roster.size()<2:
        return
    var possible: Array=[]
    for i in range(roster.size()):
        if i!=player_index:
            possible.append(i)
    opponent_index=int(possible[rng.randi_range(0,possible.size()-1)])
    _start()

func _start() -> void:
    player_hp=Rules.MAX_HP
    opponent_hp=Rules.MAX_HP
    player_strong_rest=0
    opponent_strong_rest=0
    finished=false
    busy=false
    last_damage=0
    last_effect=""
    last_message="✨ 準備好了嗎？按招式開始對決！"
    battle_biome=Scenery.choose_biome(roster[opponent_index].get("types",[]))
    scene_variant=rng.randi_range(0,2)
    _render()
    say_requested.emit("%s，準備好了嗎？要跟%s對決囉！按招式攻擊！" %
        [str(roster[player_index]["name"]),str(roster[opponent_index]["name"])])

func _health_bar(value: int, is_player: bool) -> VBoxContainer:
    var root=VBoxContainer.new()
    root.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    var name=str(roster[player_index if is_player else opponent_index]["name"])
    root.add_child(_text(("💗 "+name) if is_player else ("🤖 "+name),20,true))
    var bar=ProgressBar.new()
    bar.name="PlayerHealth" if is_player else "OpponentHealth"
    bar.min_value=0
    bar.max_value=Rules.MAX_HP
    bar.value=value
    bar.show_percentage=false
    bar.custom_minimum_size.y=22
    bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    var back=StyleBoxFlat.new()
    back.bg_color=Color("#D6E5E8")
    back.set_corner_radius_all(11)
    bar.add_theme_stylebox_override("background",back)
    var fill=StyleBoxFlat.new()
    fill.bg_color=Color("#49BD89") if value>50 else (Color("#F0C14F") if value>25 else Color("#F47B72"))
    fill.set_corner_radius_all(11)
    bar.add_theme_stylebox_override("fill",fill)
    root.add_child(bar)
    root.add_child(_text("❤️ %d / 100" % value,17,true))
    return root

func _hud_panel(content: Control) -> PanelContainer:
    var box=PanelContainer.new()
    box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    var skin=StyleBoxFlat.new()
    skin.bg_color=Color("#EDF8F9",.97)
    skin.border_color=Color("#FFFFFF")
    skin.set_border_width_all(2)
    skin.set_corner_radius_all(15)
    skin.content_margin_left=12
    skin.content_margin_right=12
    skin.content_margin_top=6
    skin.content_margin_bottom=6
    skin.shadow_size=4
    skin.shadow_color=Color("#526575",.12)
    box.add_theme_stylebox_override("panel",skin)
    box.add_child(content)
    return box

func _battle() -> void:
    var root=_clear()
    root.name="BattleRoot"
    var compact=get_viewport_rect().size.y<680.0
    root.add_theme_constant_override("separation",5 if compact else 7)
    var headline=HBoxContainer.new()
    headline.name="BattleHealthHUD"
    headline.add_theme_constant_override("separation",10)
    root.add_child(headline)
    headline.add_child(_hud_panel(_health_bar(player_hp,true)))
    var swords=_text("⚔️",24,true)
    swords.custom_minimum_size.x=48
    swords.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
    headline.add_child(swords)
    headline.add_child(_hud_panel(_health_bar(opponent_hp,false)))
    var scene= Arena.new()
    scene.name="BattleArena"
    scene.custom_minimum_size.y=168 if compact else 238
    scene.configure(roster[player_index],roster[opponent_index],battle_biome,scene_variant)
    root.add_child(scene)
    arena_node=scene
    player_portrait=scene.player_portrait
    opponent_portrait=scene.opponent_portrait

    var message_box=PanelContainer.new()
    message_box.name="BattleMessageCard"
    var message_skin=StyleBoxFlat.new()
    message_skin.bg_color=Color("#F3F9FC")
    message_skin.border_color=Color("#CCDFEA")
    message_skin.set_border_width_all(2)
    message_skin.set_corner_radius_all(16)
    message_skin.content_margin_left=11
    message_skin.content_margin_right=11
    message_skin.content_margin_top=4
    message_skin.content_margin_bottom=4
    message_box.add_theme_stylebox_override("panel",message_skin)
    root.add_child(message_box)
    var status=_text(last_message,19 if compact else 20,true)
    status.name="BattleStatus"
    status.custom_minimum_size.y=31 if compact else 37
    status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    message_box.add_child(status)
    move_buttons.clear()
    if not finished:
        var attacks=HBoxContainer.new()
        attacks.name="AttackButtons"
        attacks.add_theme_constant_override("separation",12)
        root.add_child(attacks)
        var data: Array=Rules.moves_for(int(roster[player_index]["id"]))
        for i in range(2):
            var atk: Array=data[i]
            var label=Rules.icon(str(atk[1]))+" "+str(atk[0])
            var en=Rules.icon(str(atk[1]))+" "+str(Rules.EN_MOVES.get(str(atk[0]),atk[0]))
            if i==1:
                label+=" ✨"
                en+=" ✨"
            var btn=_button(label,en,Color("#DDF2E8") if i==0 else Color("#FFEDBF"))
            btn.name="Attack_%d" % i
            btn.custom_minimum_size.y=54 if compact else 62
            btn.disabled=busy or (i==1 and player_strong_rest>0)
            btn.tooltip_text="每回合可用" if i==0 else "強力招式使用後需休息一回合"
            btn.pressed.connect(play_move.bind(i))
            attacks.add_child(btn)
            move_buttons.append(btn)
        if player_strong_rest>0:
            root.add_child(_text("⏳ 強力招式休息中",15,true))
    else:
        var actions=HBoxContainer.new()
        actions.name="BattleResultActions"
        actions.add_theme_constant_override("separation",10)
        root.add_child(actions)
        var again=_button("🔁 再戰一次","🔁 Rematch",Color("#DFF2E9"))
        again.pressed.connect(_start)
        actions.add_child(again)
        var change=_button("🔄 換對手","🔄 New Opponent",Color("#FFEAC8"))
        change.pressed.connect(_new_opponent)
        actions.add_child(change)
    var leave=_button("🏠 回圖鑑","🏠 Back",Color("#E9EDF6"))
    leave.custom_minimum_size.y=40 if compact else 43
    leave.pressed.connect(func(): leave_requested.emit())
    root.add_child(leave)

func _new_opponent() -> void:
    opponent_index=-1
    _render()

func play_move(slot: int) -> void:
    if player_index<0 or opponent_index<0 or busy or finished:
        return
    if slot<0 or slot>1 or (slot==1 and player_strong_rest>0):
        return
    busy=true
    var attacker: Dictionary=roster[player_index]
    var defender: Dictionary=roster[opponent_index]
    var result: Dictionary=Rules.strike(attacker,defender,slot,rng)
    opponent_hp=Rules.clamp_health(opponent_hp,int(result["damage"]))
    player_strong_rest=1 if slot==1 else maxi(0,player_strong_rest-1)
    var hint=_result_hint(result)
    last_damage=int(result["damage"])
    last_effect=str(result["type"])
    last_message="%s %s！💥 -%d HP%s" % [
        Rules.icon(str(result["type"])),str(result["name"]),last_damage,hint]
    _battle()
    if opponent_hp==0:
        _finish(true)
        if is_instance_valid(arena_node):
            arena_node.play_impact(true,str(result["type"]),last_damage,float(result["effectiveness"]))
        return
    if is_instance_valid(arena_node):
        arena_node.play_impact(true,str(result["type"]),last_damage,float(result["effectiveness"]))
    say_requested.emit("%s使出了%s！%s受到%d點傷害。%s" %
        [str(attacker["name"]),str(result["name"]),str(defender["name"]),last_damage,_narrated_hint(result)])
    await get_tree().create_timer(0.9).timeout
    if not is_inside_tree() or finished:
        return
    _cpu_turn()

func _cpu_turn() -> void:
    var slot=1 if opponent_strong_rest==0 and rng.randf()<.45 else 0
    var result: Dictionary=Rules.strike(roster[opponent_index],roster[player_index],slot,rng)
    player_hp=Rules.clamp_health(player_hp,int(result["damage"]))
    opponent_strong_rest=1 if slot==1 else maxi(0,opponent_strong_rest-1)
    last_damage=int(result["damage"])
    last_effect=str(result["type"])
    last_message="🤖 %s %s！💥 -%d HP%s" % [
        Rules.icon(str(result["type"])),str(result["name"]),last_damage,_result_hint(result)]
    if player_hp==0:
        _finish(false)
        if is_instance_valid(arena_node):
            arena_node.play_impact(false,str(result["type"]),last_damage,float(result["effectiveness"]))
        return
    busy=false
    _battle()
    if is_instance_valid(arena_node):
        arena_node.play_impact(false,str(result["type"]),last_damage,float(result["effectiveness"]))
    say_requested.emit("換%s囉！牠使出了%s！你受到%d點傷害。輪到你了！" %
        [str(roster[opponent_index]["name"]),str(result["name"]),last_damage])

func _result_hint(result: Dictionary) -> String:
    if float(result["effectiveness"])>1.0:
        return " 🌟"
    if float(result["effectiveness"])<1.0:
        return " 🛡️"
    return ""

func _narrated_hint(result: Dictionary) -> String:
    if float(result["effectiveness"])>1.0:
        return "屬性剋制，效果更好！"
    if float(result["effectiveness"])==0.0:
        return "這個屬性沒有造成傷害，下次換一招！"
    if float(result["effectiveness"])<1.0:
        return "對手擋住了一些傷害！"
    return ""

func _flash(target: Control, type_name: String) -> void:
    if not is_instance_valid(target):
        return
    var color=Rules.type_color(type_name)
    var tween=create_tween()
    tween.tween_property(target,"modulate",color,.13)
    tween.tween_property(target,"modulate",LIGHT,.23)

func _finish(player_won: bool) -> void:
    finished=true
    busy=false
    var winner: Dictionary=roster[player_index if player_won else opponent_index]
    last_message="🏆 %s獲勝！🎉" % str(winner["name"]) if player_won else "💗 這次%s贏了，再玩一次吧！" % str(winner["name"])
    _battle()
    if player_won:
        win_recorded.emit(player_index)
        say_requested.emit("%s贏得對決！太棒了！按再戰一次還可以繼續玩！" % str(winner["name"]))
    else:
        say_requested.emit("這次%s贏了，沒關係，我們再挑戰一次！" % str(winner["name"]))
