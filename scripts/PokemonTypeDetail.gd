extends Control
## Big, tappable and voice-first elemental guide for children aged four.
## Anchored full-screen so the parent Pokedex remains fixed and scrollable.
signal close_requested
signal speak_requested(message: String)

const Rules=preload("res://scripts/PokemonBattleRules.gd")
const INK=Color("#29445B")
const TIPS={
    "一般":"像跑步和跳躍，練習最基本的身體動作。",
    "火":"像暖暖的火苗，能使出亮亮的火花。",
    "水":"像清涼的水花，能噴出有力的水柱。",
    "電":"像閃亮的閃電，會發出啪滋啪滋的電光。",
    "草":"像陽光下的小植物，能使用藤蔓和葉子。",
    "冰":"像冰冰涼涼的雪花，能使出小冰塊。",
    "格鬥":"像練習運動的小勇士，擅長拳腳動作。",
    "毒":"像需要小心的有毒植物，使用特殊的毒招式。",
    "地面":"像腳下的土地和石頭，能讓地面動一動。",
    "飛行":"像在天空飛翔的小鳥，會使用翅膀和風。",
    "超能力":"像神奇的念力，可以用心靈的力量推動物品。",
    "蟲":"像花園裡的小昆蟲，會爬行、吐絲或飛舞。",
    "岩石":"像堅固的石頭，能用石塊保護自己。",
    "幽靈":"像奇妙的小影子，可以使用神秘的能量。",
    "龍":"像故事裡強壯的龍，會使出有力的招式。",
    "惡":"像聰明的小夜行者，擅長出其不意的動作。",
    "鋼":"像閃閃發亮的金屬，很堅硬。",
    "妖精":"像彩虹與小星星，有溫柔又神奇的力量。"
}
const EN_TYPES={
    "一般":"Normal","火":"Fire","水":"Water","電":"Electric",
    "草":"Grass","冰":"Ice","格鬥":"Fighting","毒":"Poison",
    "地面":"Ground","飛行":"Flying","超能力":"Psychic","蟲":"Bug",
    "岩石":"Rock","幽靈":"Ghost","龍":"Dragon","惡":"Dark",
    "鋼":"Steel","妖精":"Fairy"
}

var pokemon_data: Dictionary={}
var focused_type: String=""
var english_buttons: bool=false

func configure(friend: Dictionary,type_name: String,english: bool=false) -> void:
    pokemon_data=friend
    focused_type=type_name
    english_buttons=english

func _ready() -> void:
    name="PokemonTypeDetailOverlay"
    mouse_filter=Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var backdrop=ColorRect.new()
    backdrop.name="TypeBackdrop"
    backdrop.color=Color("#14263A",.73)
    backdrop.mouse_filter=Control.MOUSE_FILTER_STOP
    add_child(backdrop)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var panel=PanelContainer.new()
    panel.name="TypeDetailDialog"
    panel.mouse_filter=Control.MOUSE_FILTER_STOP
    add_child(panel)
    panel.anchor_left=.18
    panel.anchor_right=.82
    panel.anchor_top=.075
    panel.anchor_bottom=.925
    var skin=StyleBoxFlat.new()
    skin.bg_color=Color("#FCFEFF")
    skin.border_color=Rules.type_color(focused_type).darkened(.08)
    skin.set_border_width_all(5)
    skin.set_corner_radius_all(28)
    skin.content_margin_left=18
    skin.content_margin_right=18
    skin.content_margin_top=12
    skin.content_margin_bottom=12
    skin.shadow_color=Color("#102C47",.26)
    skin.shadow_size=14
    panel.add_theme_stylebox_override("panel",skin)

    var shell=VBoxContainer.new()
    shell.add_theme_constant_override("separation",8)
    panel.add_child(shell)
    var header=HBoxContainer.new()
    header.add_theme_constant_override("separation",10)
    shell.add_child(header)
    var heading=_label("🧩 屬性小百科" if not english_buttons else "🧩 Type Guide",28)
    header.add_child(heading)
    var close=_button("✕","✕",Color("#FFE3DB"),Vector2(68,55))
    close.name="CloseTypeDetail"
    close.pressed.connect(func(): close_requested.emit())
    header.add_child(close)

    var scroll=ScrollContainer.new()
    scroll.name="TypeDetailScroll"
    scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    shell.add_child(scroll)
    var body=VBoxContainer.new()
    body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation",9)
    scroll.add_child(body)

    var hero=PanelContainer.new()
    hero.name="TypeHero"
    var hero_skin=StyleBoxFlat.new()
    hero_skin.bg_color=Rules.type_color(focused_type).lightened(.08)
    hero_skin.set_corner_radius_all(22)
    hero_skin.content_margin_left=15
    hero_skin.content_margin_top=10
    hero_skin.content_margin_right=15
    hero_skin.content_margin_bottom=10
    hero.add_theme_stylebox_override("panel",hero_skin)
    body.add_child(hero)
    var hero_row=HBoxContainer.new()
    hero_row.add_theme_constant_override("separation",22)
    hero.add_child(hero_row)
    var symbol=_label(Rules.icon(focused_type),92)
    symbol.name="LargeTypeIcon"
    symbol.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    symbol.custom_minimum_size=Vector2(140,116)
    symbol.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
    hero_row.add_child(symbol)
    var title_col=VBoxContainer.new()
    title_col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    title_col.alignment=BoxContainer.ALIGNMENT_CENTER
    hero_row.add_child(title_col)
    title_col.add_child(_label("%s屬性" % focused_type,32))
    if english_buttons:
        title_col.add_child(_label(str(EN_TYPES.get(focused_type,focused_type)),23))
    title_col.add_child(_label("🐾 %s" % str(pokemon_data.get("name","")),20))

    body.add_child(_label("✨ "+str(TIPS.get(focused_type,"有自己獨特的招式和力量。")),22))
    var attack_chart: Array=Rules.CHART.get(focused_type,[[],[],[]])[0]
    _icon_row(body,"✨ 這種招式很擅長對付" if not english_buttons else "✨ Strong Against",attack_chart)
    var weak: Array=Rules.weaknesses(pokemon_data.get("types",[]))
    _icon_row(body,"⚠️ %s 比較怕" % str(pokemon_data.get("name","")),weak)
    if pokemon_data.get("types",[]).size()>1:
        body.add_child(_label("💡 同時擁有兩種屬性，弱點是一起計算的喔！",17))
    body.add_child(_label("🗣️ 按下方的喇叭，讓我唸給你聽！",17))

    var footer=HBoxContainer.new()
    footer.name="TypeDetailActions"
    footer.add_theme_constant_override("separation",12)
    shell.add_child(footer)
    var speak=_button("🔊 聽屬性介紹","🔊 Listen",Color("#D8F5E7"),Vector2(200,63))
    speak.name="SpeakTypeDetail"
    speak.pressed.connect(func(): speak_requested.emit(narration()))
    footer.add_child(speak)
    var done=_button("✔ 返回","✔ Back",Color("#E3EDF8"),Vector2(150,63))
    done.name="DoneTypeDetail"
    done.pressed.connect(func(): close_requested.emit())
    footer.add_child(done)

func _icon_row(parent: VBoxContainer,heading: String,items: Array) -> void:
    parent.add_child(_label(heading,21))
    var flow=HFlowContainer.new()
    flow.add_theme_constant_override("h_separation",9)
    flow.add_theme_constant_override("v_separation",7)
    parent.add_child(flow)
    if items.is_empty():
        flow.add_child(_label("⭐ 沒有特別的相剋屬性",19))
        return
    for item in items:
        var kind=str(item)
        var tile=PanelContainer.new()
        tile.name="SmallType_"+kind
        var skin=StyleBoxFlat.new()
        skin.bg_color=Rules.type_color(kind)
        skin.set_corner_radius_all(16)
        skin.content_margin_left=8
        skin.content_margin_top=5
        skin.content_margin_bottom=5
        skin.content_margin_right=8
        tile.add_theme_stylebox_override("panel",skin)
        flow.add_child(tile)
        var col=VBoxContainer.new()
        col.alignment=BoxContainer.ALIGNMENT_CENTER
        tile.add_child(col)
        var icon=_label(Rules.icon(kind),35)
        icon.custom_minimum_size=Vector2(73,37)
        icon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        col.add_child(icon)
        var text=_label(kind,18)
        text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        col.add_child(text)

func _label(t: String,font_size: int) -> Label:
    var label=Label.new()
    label.text=t
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",INK)
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    return label

func _button(zh: String,en: String,color: Color,minsize: Vector2) -> Button:
    var btn=Button.new()
    btn.text=en if english_buttons else zh
    btn.custom_minimum_size=minsize
    btn.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    btn.add_theme_font_size_override("font_size",23)
    btn.add_theme_color_override("font_color",INK)
    btn.add_theme_color_override("font_hover_color",INK)
    btn.add_theme_color_override("font_pressed_color",INK)
    btn.focus_mode=Control.FOCUS_NONE
    var skin=StyleBoxFlat.new()
    skin.bg_color=color
    skin.set_corner_radius_all(16)
    skin.content_margin_left=11
    skin.content_margin_right=11
    skin.content_margin_top=7
    skin.content_margin_bottom=7
    btn.add_theme_stylebox_override("normal",skin)
    var hover=skin.duplicate()
    hover.bg_color=color.lightened(.08)
    btn.add_theme_stylebox_override("hover",hover)
    btn.add_theme_stylebox_override("pressed",skin)
    btn.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
    return btn

func narration() -> String:
    var targets=PackedStringArray()
    for item in Rules.CHART.get(focused_type,[[],[],[]])[0]:
        targets.append(str(item))
    var weaknesses=PackedStringArray()
    for item in Rules.weaknesses(pokemon_data.get("types",[])):
        weaknesses.append(str(item))
    var first="我是%s屬性。%s" % [focused_type,str(TIPS.get(focused_type,""))]
    if not targets.is_empty():
        first+="這種招式比較擅長對付%s屬性。" % "、".join(targets)
    if not weaknesses.is_empty():
        first+="%s比較怕%s屬性的招式。" % [str(pokemon_data.get("name","")), "、".join(weaknesses)]
    return first
