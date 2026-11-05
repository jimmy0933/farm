extends Control
## Voice-first interactive Pokemon learning game, built for ages 4+.
## All descriptions are original, child-friendly summaries of public Pokédex data.

const MODES = ["圖鑑", "玩遊戲", "照顧朋友", "貼紙館", "寶可夢對決", "設定"]
const MODE_ICONS = ["📖", "🎯", "💗", "🌟", "⚔️", "⚙️"]
const PokemonBattle=preload("res://scripts/PokemonBattle.gd")
const BattleRules=preload("res://scripts/PokemonBattleRules.gd")
const KidsTouchScroll=preload("res://scripts/KidsTouchScroll.gd")
const TypeDetail=preload("res://scripts/PokemonTypeDetail.gd")
const EN_BUTTONS={
    "圖鑑":"Pokédex", "玩遊戲":"Guess", "照顧朋友":"Care",
    "貼紙館":"Stickers", "寶可夢對決":"Battle", "設定":"Settings",
    "再聽一次":"Replay", "停止":"Stop", "聽我介紹":"Listen",
    "屬性":"Types", "身高體重":"Size", "身高":"Height",
    "體重":"Weight", "特性":"Ability", "聽好玩的秘密":"Story",
    "換下一題":"Next", "換一個朋友":"Next Friend",
    "給牠吃點心":"Feed", "一起玩耍":"Play", "休息一下":"Rest",
    "輕輕打招呼":"Hello", "回圖鑑":"Back", "中文":"Chinese",
    "變更語言":"Language", "English":"English",
    "電擊":"Thunder Shock", "影子球":"Shadow Ball",
    "電光一閃":"Quick Attack", "催眠術":"Hypnosis",
    "種子炸彈":"Seed Bomb", "木枝突刺":"Branch Poke",
    "飛葉快刀":"Razor Leaf", "水槍":"Water Gun",
    "縮入殼中":"Withdraw", "幻象光線":"Psybeam",
    "念力":"Confusion", "火花":"Ember", "抓":"Scratch",
    "水炮":"Hydro Pump", "高速星星":"Swift",
    "撞擊":"Tackle", "冰礫":"Ice Shard", "地震":"Earthquake",
    "毒針":"Poison Sting", "蟲咬":"Bug Bite", "藤鞭":"Vine Whip"
}
const DARK = Color("#263C55")
const MUTED = Color("#587084")
const PALE = Color("#F0FAFC")
const AQUA = Color("#4FBEBC")
const GOLD = Color("#FFD771")
const WHITE = Color("#FFFFFF")

var pokemon: Array = []
var mode: int = 0
var selected: int = 0
var quiz_target: int = 0
var quiz_options: Array[int] = []
var quiz_solved: bool = false
var hearts: Dictionary = {}
var discovered: Dictionary = {}
var battle_wins: Dictionary = {}
var button_language: String = "zh"
var battle_view: Control
var content_scroller: ScrollContainer
var pokemon_roster_scroll: ScrollContainer
var pokemon_detail_scroll: ScrollContainer
var type_detail_popup: Control
var roster_scroll_position: int=0
var last_speech: String = ""
var voice_id: String = ""
var speech_serial: int=0
var speech_finished_serial: int=0
var speech_callbacks_enabled: bool=false
var rng := RandomNumberGenerator.new()
var content_host: VBoxContainer
var caption_label: Label
var voice_note: Label


func _ready() -> void:
    rng.randomize()
    var raw := FileAccess.get_file_as_string("res://data/pokemon.json")
    var parsed = JSON.parse_string(raw)
    if typeof(parsed) != TYPE_ARRAY:
        push_error("Cannot load Pokémon educational data")
        return
    pokemon = parsed
    _read_progress()
    _set_chinese_font()
    _choose_voice()
    _install_speech_callbacks()
    _compose()
    call_deferred("_welcome")


func _set_chinese_font() -> void:
    var font_path := "res://assets/fonts/NotoSansCJKtc-Regular.otf"
    if ResourceLoader.exists(font_path):
        var new_theme := Theme.new()
        new_theme.default_font = load(font_path)
        new_theme.default_font_size = 22
        theme = new_theme


func _choose_voice() -> void:
    if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        return
    for locale in ["zh_TW", "zh-Hant-TW", "zh_TW_#Hant", "zh_CN", "zh"]:
        var ids := DisplayServer.tts_get_voices_for_language(locale)
        if ids.size() > 0:
            voice_id = ids[0]
            return
    for voice in DisplayServer.tts_get_voices():
        if str(voice.get("language", "")).to_lower().begins_with("zh"):
            voice_id = str(voice.get("id", ""))
            return


func _welcome() -> void:
    _say("歡迎來到寶可夢小小探險隊！點一隻寶可夢，就能聽牠介紹自己。我們一起玩吧！")


func _install_speech_callbacks() -> void:
    if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        return
    # Godot reports the exact utterance ID when Android finishes narration.
    # This replaces the old fixed 0.9-second handover during battles.
    DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED,Callable(self,"_on_speech_completed"))
    DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED,Callable(self,"_on_speech_completed"))
    speech_callbacks_enabled=true


func _on_speech_completed(utterance_id: int) -> void:
    if utterance_id==speech_serial:
        speech_finished_serial=utterance_id


func _say(message: String) -> void:
    last_speech=message
    speech_serial+=1
    if is_instance_valid(caption_label):
        caption_label.text="🔊 "+message
    if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        if is_instance_valid(voice_note):
            voice_note.text="需要手機語音功能"
        speech_finished_serial=speech_serial
        return
    if voice_id.is_empty():
        _choose_voice()
    if not voice_id.is_empty():
        DisplayServer.tts_speak(message,voice_id,100,1.07,0.85,speech_serial,true)
    else:
        speech_finished_serial=speech_serial
        if is_instance_valid(voice_note):
            voice_note.text="請安裝繁體中文語音"


func _say_and_wait(message: String) -> void:
    # When Android provides TTS completion callbacks, wait for the actual
    # narration to finish. A generous safety timeout handles broken engines;
    # no-voice devices use an accessible timed pause instead.
    _say(message)
    var current_id=speech_serial
    var voice_available=speech_callbacks_enabled and not voice_id.is_empty()
    if not voice_available:
        await get_tree().create_timer(clampf(float(message.length())*.07,1.1,2.6)).timeout
        return
    var max_seconds=clampf(float(message.length())*.29+3.0,4.0,22.0)
    var elapsed=0.0
    while is_inside_tree() and speech_serial==current_id and speech_finished_serial!=current_id and elapsed<max_seconds:
        await get_tree().create_timer(.10).timeout
        elapsed+=.10
    # Never issue a second narration until any TTS engine stall is resolved.
    if speech_serial==current_id and speech_finished_serial!=current_id and DisplayServer.tts_is_speaking():
        DisplayServer.tts_stop()

func _read_progress() -> void:
    if not FileAccess.file_exists("user://pokemon_kids_progress.json"):
        return
    var save = JSON.parse_string(FileAccess.get_file_as_string("user://pokemon_kids_progress.json"))
    if typeof(save) == TYPE_DICTIONARY:
        hearts = save.get("hearts", {})
        discovered = save.get("discovered", {})
        battle_wins = save.get("battle_wins", {})
        button_language = "en" if str(save.get("button_language", "zh")) == "en" else "zh"


func _save_progress() -> void:
    var save_file := FileAccess.open("user://pokemon_kids_progress.json", FileAccess.WRITE)
    if save_file != null:
        save_file.store_string(JSON.stringify({"hearts": hearts, "discovered": discovered, "battle_wins":battle_wins, "button_language":button_language}))


func _add_heart(index: int, amount: int = 1) -> void:
    var key := str(pokemon[index]["id"])
    hearts[key] = mini(int(hearts.get(key, 0)) + amount, 99)
    discovered[key] = true
    _save_progress()


func _heart_count(index: int) -> int:
    return int(hearts.get(str(pokemon[index]["id"]), 0))


func _styled_panel(color: Color, rounded: int = 26) -> PanelContainer:
    var panel := PanelContainer.new()
    var skin := StyleBoxFlat.new()
    skin.bg_color = color
    skin.set_corner_radius_all(rounded)
    skin.content_margin_left = 13.0
    skin.content_margin_right = 13.0
    skin.content_margin_top = 10.0
    skin.content_margin_bottom = 10.0
    skin.shadow_color = Color(0.12, 0.35, 0.47, 0.1)
    skin.shadow_size = 3
    panel.add_theme_stylebox_override("panel", skin)
    return panel


func _translated_button(raw: String) -> String:
    if button_language!="en":
        return raw
    var result=raw
    for chinese in EN_BUTTONS:
        if result.contains(str(chinese)):
            result=result.replace(str(chinese),str(EN_BUTTONS[chinese]))
    return result

func _pretty_button(text: String, bg: Color, min_size: Vector2 = Vector2(175, 66)) -> Button:
    var button := Button.new()
    button.text = _translated_button(text)
    button.custom_minimum_size = min_size
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 21 if button_language=="en" else 23)
    button.add_theme_color_override("font_color", DARK)
    button.add_theme_color_override("font_hover_color", DARK)
    button.add_theme_color_override("font_pressed_color", DARK)
    var normal := StyleBoxFlat.new()
    normal.bg_color = bg
    normal.set_corner_radius_all(21)
    normal.content_margin_left = 12
    normal.content_margin_right = 12
    normal.content_margin_top = 10
    normal.content_margin_bottom = 10
    normal.shadow_size = 3
    normal.shadow_color = Color(0.1, 0.22, 0.29, 0.15)
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = bg.lightened(0.12)
    var down := normal.duplicate() as StyleBoxFlat
    down.bg_color = bg.darkened(0.07)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", down)
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    return button


func _label(text: String, size: int = 24, color: Color = DARK, align_text: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var out := Label.new()
    out.text = text
    out.add_theme_font_size_override("font_size", size)
    out.add_theme_color_override("font_color", color)
    out.horizontal_alignment = align_text
    out.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    out.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    out.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return out


func _gap(parent: Node, value: int = 10) -> void:
    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(value, value)
    parent.add_child(spacer)


func _compose() -> void:
    type_detail_popup=null
    for child in get_children():
        remove_child(child)
        child.queue_free()
    var bg := ColorRect.new()
    bg.color = PALE
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    var outer := MarginContainer.new()
    outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outer.add_theme_constant_override("margin_left", 20)
    outer.add_theme_constant_override("margin_right", 20)
    outer.add_theme_constant_override("margin_top", 12)
    outer.add_theme_constant_override("margin_bottom", 10)
    add_child(outer)

    # Use anchored bands instead of a VBox, whose children's large minimum
    # sizes formerly pushed the speech footer offscreen.
    var frame:=Control.new()
    frame.name="FixedFrame"
    frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
    outer.add_child(frame)
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var top := HBoxContainer.new()
    top.custom_minimum_size = Vector2(0, 43)
    top.add_theme_constant_override("separation", 10)
    frame.add_child(top)
    top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    top.offset_top=0
    top.offset_bottom=44
    top.add_child(_label("🌈 寶可夢小小探險隊", 29))
    voice_note = _label("4歲也能自己玩", 18, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
    voice_note.custom_minimum_size = Vector2(210, 42)
    top.add_child(voice_note)

    var nav := HBoxContainer.new()
    nav.add_theme_constant_override("separation", 7)
    frame.add_child(nav)
    nav.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    nav.offset_top=49
    nav.offset_bottom=108
    for i in range(MODES.size()):
        var color := GOLD if i == mode else WHITE
        var button := _pretty_button(MODE_ICONS[i] + "  " + MODES[i], color, Vector2(132, 55))
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.pressed.connect(_change_mode.bind(i))
        nav.add_child(button)

    # Only the middle scrolls. The nav and voice buttons never drop offscreen.
    content_scroller=ScrollContainer.new()
    content_scroller.name="MainContentScroll"
    content_scroller.size_flags_vertical=Control.SIZE_EXPAND_FILL
    content_scroller.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    content_scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    content_scroller.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED if mode==0 else ScrollContainer.SCROLL_MODE_AUTO
    content_scroller.clip_contents=true
    frame.add_child(content_scroller)
    content_scroller.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    content_scroller.offset_top=114
    content_scroller.offset_bottom=-78
    content_host = VBoxContainer.new()
    content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_host.add_theme_constant_override("separation", 8)
    content_scroller.add_child(content_host)
    match mode:
        0: _show_friends()
        1: _show_guess()
        2: _show_care()
        3: _show_stickers()
        4: _show_battle()
        5: _show_settings()

    var caption_panel := _styled_panel(WHITE, 22)
    caption_panel.custom_minimum_size = Vector2(0, 68)
    caption_panel.size_flags_vertical=Control.SIZE_SHRINK_END
    caption_panel.name="VoiceFooter"
    frame.add_child(caption_panel)
    caption_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    caption_panel.offset_top=-70
    caption_panel.offset_bottom=0
    var speech_row := HBoxContainer.new()
    speech_row.add_theme_constant_override("separation", 8)
    caption_panel.add_child(speech_row)
    caption_label = _label("🔊 " + (last_speech if not last_speech.is_empty() else "歡迎來探險，按圖片就會說話喔！"), 20, MUTED)
    caption_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    caption_label.autowrap_mode=TextServer.AUTOWRAP_OFF
    caption_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
    caption_label.tooltip_text=last_speech
    speech_row.add_child(caption_label)
    var replay := _pretty_button("🔊 再聽一次", Color("#D9F8ED"), Vector2(152, 49))
    replay.pressed.connect(_replay)
    speech_row.add_child(replay)
    var stop := _pretty_button("⏹ 停止", Color("#FFE5E4"), Vector2(103, 49))
    stop.pressed.connect(func(): DisplayServer.tts_stop())
    speech_row.add_child(stop)


func _change_mode(index: int) -> void:
    mode = index
    _compose()
    var prompt := ["挑一個寶可夢朋友，點圖片就會說話！", "聽問題，找出正確的寶可夢！", "一起吃點心、玩耍、休息、打招呼！", "每次互動都可以收集愛心貼紙！", "先選自己的寶可夢，再選對手，按招式就能對決囉！", "可以切換按鈕的中文或英文，語音仍使用中文。"]
    _say(prompt[mode])


func _show_battle() -> void:
    battle_view=PokemonBattle.new()
    battle_view.name="PokemonBattle"
    battle_view.configure(pokemon,button_language=="en",self)
    battle_view.say_requested.connect(_say)
    battle_view.leave_requested.connect(_change_mode.bind(0))
    battle_view.win_recorded.connect(_record_battle_win)
    content_host.add_child(battle_view)


func _record_battle_win(index: int) -> void:
    var key=str(pokemon[index]["id"])
    battle_wins[key]=int(battle_wins.get(key,0))+1
    _add_heart(index,2)
    _save_progress()


func _show_settings() -> void:
    var panel=_styled_panel(WHITE)
    content_host.add_child(panel)
    var col=VBoxContainer.new()
    col.add_theme_constant_override("separation",13)
    panel.add_child(col)
    col.add_child(_label("⚙️ 設定",30,DARK,HORIZONTAL_ALIGNMENT_CENTER))
    col.add_child(_label("🌍 按鈕說明語言",24,DARK,HORIZONTAL_ALIGNMENT_CENTER))
    var row=HBoxContainer.new()
    row.add_theme_constant_override("separation",15)
    col.add_child(row)
    var chinese=_pretty_button("🇹🇼 中文",GOLD if button_language=="zh" else PALE,Vector2(220,78))
    chinese.name="ChineseButtons"
    chinese.pressed.connect(_change_button_language.bind("zh"))
    row.add_child(chinese)
    var english=_pretty_button("🇬🇧 English",GOLD if button_language=="en" else PALE,Vector2(220,78))
    english.name="EnglishButtons"
    english.pressed.connect(_change_button_language.bind("en"))
    row.add_child(english)
    col.add_child(_label("🔊 語音仍用中文介紹寶可夢，只有按鈕文字切換語言。",20,MUTED,HORIZONTAL_ALIGNMENT_CENTER))
    col.add_child(_label("👆 可以試著切換，然後點上方圖示看看！",19,MUTED,HORIZONTAL_ALIGNMENT_CENTER))
    var replay=_pretty_button("🔊 再聽一次",PALE,Vector2(0,58))
    replay.pressed.connect(func(): _say("上面的按鈕可以選中文或英文，語音會繼續使用中文。"))
    col.add_child(replay)


func _change_button_language(language: String) -> void:
    if language not in ["zh","en"]:
        return
    button_language=language
    _save_progress()
    _compose()
    _say("按鈕已切換成英文！" if language=="en" else "按鈕已切換成中文！")

func _picture(index: int, height_px: float = 160) -> Control:
    var m: Dictionary = pokemon[index]
    var img_path := "res://assets/pokemon/%d.png" % int(m["id"])
    if ResourceLoader.exists(img_path):
        var image := TextureRect.new()
        image.texture = load(img_path)
        image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        image.custom_minimum_size = Vector2(0, height_px)
        image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        image.size_flags_vertical = Control.SIZE_EXPAND_FILL
        image.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return image
    var fallback := _label(str(m["emoji"]), 76, DARK, HORIZONTAL_ALIGNMENT_CENTER)
    fallback.custom_minimum_size = Vector2(0, height_px)
    fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return fallback


func _creature_card(index: int, press_action: Callable, card_size: Vector2 = Vector2(150, 137)) -> PanelContainer:
    var m: Dictionary = pokemon[index]
    var panel := _styled_panel(Color(str(m["color"])), 25)
    panel.custom_minimum_size = card_size
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 1)
    panel.add_child(body)
    body.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(_picture(index, card_size.y - 57))
    var title := _label(str(m["name"]), 24, DARK, HORIZONTAL_ALIGNMENT_CENTER)
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(title)
    var hit := Button.new()
    hit.flat = true
    hit.focus_mode = Control.FOCUS_NONE
    hit.mouse_filter = Control.MOUSE_FILTER_STOP
    hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
    hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
    hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
    hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    hit.pressed.connect(press_action)
    panel.add_child(hit)
    hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    return panel


func _show_friends() -> void:
    # Both panes retain fixed-height independent scrolling as the roster grows.
    # The two panels get their own FIXED-height viewports. Previously the
    # right-hand detail's long content expanded the whole HBox, making the
    # roster scroll as tall as all 12 cards. The only draggable surface was
    # then the *outer* page, which made both columns feel stuck on phones.
    var columns=Control.new()
    columns.name="PokedexColumns"
    columns.custom_minimum_size.y=maxf(286.0,get_viewport_rect().size.y-248.0)
    columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    content_host.add_child(columns)

    var left=_styled_panel(WHITE)
    left.name="PokemonRosterPanel"
    columns.add_child(left)
    left.anchor_left=0.0
    left.anchor_right=.43
    left.anchor_top=0.0
    left.anchor_bottom=1.0
    left.offset_right=-7.0
    var left_col=VBoxContainer.new()
    left_col.add_theme_constant_override("separation",5)
    left.add_child(left_col)
    left_col.add_child(_label("👆 選角色   ↕️ 上下滑",19))
    var list_row=HBoxContainer.new()
    list_row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    list_row.size_flags_vertical=Control.SIZE_EXPAND_FILL
    list_row.add_theme_constant_override("separation",3)
    left_col.add_child(list_row)
    var roster_scroll=KidsTouchScroll.new()
    roster_scroll.name="PokemonRosterScroll"
    roster_scroll.swipe_speed=2.0
    roster_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    roster_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
    list_row.add_child(roster_scroll)
    pokemon_roster_scroll=roster_scroll
    var grid=GridContainer.new()
    grid.name="PokemonRosterGrid"
    grid.columns=3
    grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation",7)
    grid.add_theme_constant_override("v_separation",7)
    roster_scroll.add_child(grid)
    for i in range(pokemon.size()):
        grid.add_child(_creature_card(i,_select_friend.bind(i),Vector2(124,143)))
    _scroll_page_buttons(list_row,roster_scroll,"Roster")

    _detail_panel(columns)
    call_deferred("_restore_roster_scroll")


func _scroll_page_buttons(parent: Control,scroller: ScrollContainer,prefix: String) -> void:
    # A predictable alternative to swiping for very young children.
    var col=VBoxContainer.new()
    col.name=prefix+"PageControls"
    col.custom_minimum_size.x=51
    col.alignment=BoxContainer.ALIGNMENT_CENTER
    col.add_theme_constant_override("separation",10)
    parent.add_child(col)
    var up=_pretty_button("▲",Color("#E7F2FE"),Vector2(48,76))
    up.name=prefix+"PageUp"
    up.tooltip_text="上一頁"
    up.pressed.connect(scroller.page.bind(-1))
    col.add_child(up)
    var down=_pretty_button("▼",Color("#E7F2FE"),Vector2(48,76))
    down.name=prefix+"PageDown"
    down.tooltip_text="下一頁"
    down.pressed.connect(scroller.page.bind(1))
    col.add_child(down)


func _restore_roster_scroll() -> void:
    if is_instance_valid(pokemon_roster_scroll):
        pokemon_roster_scroll.restore(roster_scroll_position)


func _select_friend(index: int) -> void:
    if is_instance_valid(pokemon_roster_scroll) and pokemon_roster_scroll.was_dragging:
        return
    if is_instance_valid(pokemon_roster_scroll):
        roster_scroll_position=pokemon_roster_scroll.scroll_vertical
    selected = index
    _add_heart(index)
    _compose()
    _say(str(pokemon[index]["intro"]))


func _symbol_strip(parent: VBoxContainer, prefix: String, types: Array) -> void:
    var flow=HFlowContainer.new()
    flow.add_theme_constant_override("h_separation",5)
    flow.add_theme_constant_override("v_separation",4)
    parent.add_child(flow)
    var marker=_label(prefix,17,MUTED)
    marker.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
    flow.add_child(marker)
    for type_name in types:
        var name=str(type_name)
        var symbol=_label(BattleRules.icon(name),23,DARK,HORIZONTAL_ALIGNMENT_CENTER)
        symbol.custom_minimum_size=Vector2(31,28)
        symbol.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
        symbol.autowrap_mode=TextServer.AUTOWRAP_OFF
        symbol.tooltip_text=name+"屬性"
        var skin=StyleBoxFlat.new()
        skin.bg_color=BattleRules.type_color(name)
        skin.set_corner_radius_all(10)
        skin.content_margin_left=3
        skin.content_margin_right=3
        symbol.add_theme_stylebox_override("normal",skin)
        flow.add_child(symbol)



func _type_badge_panel(parent: VBoxContainer, types: Array) -> void:
    var wrapper=_styled_panel(Color("#E7F7FB"),18)
    wrapper.name="TypeBadgePanel"
    parent.add_child(wrapper)
    var col=VBoxContainer.new()
    col.add_theme_constant_override("separation",6)
    wrapper.add_child(col)
    col.add_child(_label("🧩 點大圖示看屬性與弱點",21,DARK))
    var row=HBoxContainer.new()
    row.add_theme_constant_override("separation",10)
    col.add_child(row)
    for type_name in types:
        var kind=str(type_name)
        var background=BattleRules.type_color(kind).lightened(.08)
        var badge=_pretty_button(BattleRules.icon(kind)+"  "+kind+"  ⓘ",background,Vector2(146,74))
        badge.name="TypeBadge_"+kind
        badge.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        badge.add_theme_font_size_override("font_size",29)
        badge.tooltip_text="%s屬性，點擊看大圖示、介紹和弱點" % kind
        badge.pressed.connect(_open_type_detail.bind(kind))
        row.add_child(badge)


func _open_type_detail(kind: String) -> void:
    if not BattleRules.TYPE_ICONS.has(kind):
        return
    if is_instance_valid(type_detail_popup):
        _close_type_detail()
    # KidsTouchScroll uses _input; temporarily disable behind modal so an
    # exploratory swipe on the popup never moves the Pokedex underneath.
    if is_instance_valid(pokemon_roster_scroll):
        pokemon_roster_scroll.set_process_input(false)
    if is_instance_valid(pokemon_detail_scroll):
        pokemon_detail_scroll.set_process_input(false)
    var popup=TypeDetail.new()
    popup.configure(pokemon[selected],kind,button_language=="en")
    popup.close_requested.connect(_close_type_detail)
    popup.speak_requested.connect(_say)
    add_child(popup)
    popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    type_detail_popup=popup


func _close_type_detail() -> void:
    if is_instance_valid(type_detail_popup):
        var popup=type_detail_popup
        type_detail_popup=null
        remove_child(popup)
        popup.queue_free()
    if is_instance_valid(pokemon_roster_scroll):
        pokemon_roster_scroll.set_process_input(true)
    if is_instance_valid(pokemon_detail_scroll):
        pokemon_detail_scroll.set_process_input(true)


func _detail_panel(parent: Control) -> void:
    var m: Dictionary = pokemon[selected]
    var detail := _styled_panel(Color(str(m["color"])).lightened(0.58), 27)
    detail.name="PokemonDetailPanel"
    parent.add_child(detail)
    detail.anchor_left=.43
    detail.anchor_right=1.0
    detail.anchor_top=0.0
    detail.anchor_bottom=1.0
    detail.offset_left=7.0
    var detail_row=HBoxContainer.new()
    detail_row.add_theme_constant_override("separation",4)
    detail.add_child(detail_row)
    var detail_scroll=KidsTouchScroll.new()
    detail_scroll.name="PokemonDetailScroll"
    detail_scroll.swipe_speed=1.9
    detail_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    detail_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
    detail_row.add_child(detail_scroll)
    pokemon_detail_scroll=detail_scroll
    var col := VBoxContainer.new()
    col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    col.add_theme_constant_override("separation", 8)
    detail_scroll.add_child(col)
    _scroll_page_buttons(detail_row,detail_scroll,"Detail")
    var hero := HBoxContainer.new()
    hero.add_theme_constant_override("separation", 12)
    hero.custom_minimum_size = Vector2(0, 188)
    col.add_child(hero)
    var photo := _picture(selected, 182)
    photo.custom_minimum_size = Vector2(218, 180)
    hero.add_child(photo)
    var right := VBoxContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero.add_child(right)
    right.add_child(_label("No.%04d" % int(m["id"]), 18, MUTED))
    right.add_child(_label(str(m["name"]), 37))
    var stats=HBoxContainer.new()
    stats.add_theme_constant_override("separation",6)
    right.add_child(stats)
    var height=_label("📏 %s m" % str(m["height"]),19)
    height.tooltip_text="身高：%s 公尺" % str(m["height"])
    height.autowrap_mode=TextServer.AUTOWRAP_OFF
    stats.add_child(height)
    var weight=_label("⚖️ %s kg" % str(m["weight"]),19)
    weight.tooltip_text="體重：%s 公斤" % str(m["weight"])
    weight.autowrap_mode=TextServer.AUTOWRAP_OFF
    stats.add_child(weight)
    right.add_child(_label("💗 %d" % _heart_count(selected),17,MUTED))
    var voice := _pretty_button("🔊 聽我介紹", WHITE, Vector2(220, 56))
    voice.pressed.connect(func(): _say(str(m["intro"])))
    right.add_child(voice)
    _type_badge_panel(col,m["types"])

    var bubble := _styled_panel(WHITE, 16)
    col.add_child(bubble)
    bubble.add_child(_label(str(m["intro"]), 19))
    var row_a := HBoxContainer.new()
    row_a.add_theme_constant_override("separation", 7)
    col.add_child(row_a)
    var types := _pretty_button("🔍 屬性", WHITE, Vector2(120, 55))
    types.pressed.connect(_open_type_detail.bind(str(m["types"][0])))
    row_a.add_child(types)
    var measure := _pretty_button("📏 身高", WHITE, Vector2(122, 55))
    measure.pressed.connect(_say_measurements)
    row_a.add_child(measure)
    var mass := _pretty_button("⚖️ 體重", WHITE, Vector2(122, 55))
    mass.pressed.connect(_say_measurements)
    row_a.add_child(mass)
    var special := _pretty_button("✨ 特性", WHITE, Vector2(122, 55))
    special.pressed.connect(_say_abilities)
    row_a.add_child(special)

    col.add_child(_label("🎵 點招式，聽它會做什麼：", 21))
    var moves := HBoxContainer.new()
    moves.add_theme_constant_override("separation", 8)
    col.add_child(moves)
    for move in m["moves"]:
        var move_btn := _pretty_button("🔊 " + str(move["name"]), WHITE, Vector2(160, 59))
        move_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        move_btn.pressed.connect(_say_move.bind(str(move["name"]), str(move["description"])))
        moves.add_child(move_btn)
    var story := _pretty_button("🧡 聽好玩的秘密", Color("#FFECBB"), Vector2(0, 52))
    story.pressed.connect(func(): _say(str(m["fun"])))
    col.add_child(story)


func _say_types() -> void:
    var m: Dictionary = pokemon[selected]
    var weak=BattleRules.weaknesses(m["types"])
    var weakness_names=PackedStringArray()
    for kind in weak:
        weakness_names.append(str(kind))
    _say("%s的屬性是%s。比較害怕%s屬性的招式。%s" % [
        m["name"],"和".join(PackedStringArray(m["types"])),
        "、".join(weakness_names),m["type_tip"]])


func _say_measurements() -> void:
    var m: Dictionary = pokemon[selected]
    var centimeters: int = roundi(float(m["height"]) * 100.0)
    _say("%s的身高是%d公分，體重是%s公斤。讓我們伸出手，看看有多高！" % [m["name"], centimeters, str(m["weight"])])


func _say_abilities() -> void:
    var m: Dictionary = pokemon[selected]
    var result := str(m["name"]) + "的特性有："
    for ability in m["ability"]:
        result += str(ability["name"]) + "。" + str(ability["description"])
    _say(result)


func _say_move(move_name: String, details: String) -> void:
    _add_heart(selected)
    _say("招式，" + move_name + "。" + details)


func _next_question() -> void:
    quiz_target = rng.randi_range(0, pokemon.size() - 1)
    quiz_options.clear()
    quiz_options.append(quiz_target)
    while quiz_options.size() < 3:
        var possibility := rng.randi_range(0, pokemon.size() - 1)
        if not quiz_options.has(possibility):
            quiz_options.append(possibility)
    quiz_options.shuffle()
    quiz_solved = false


func _show_guess() -> void:
    if quiz_options.is_empty():
        _next_question()
    var panel := _styled_panel(WHITE)
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_host.add_child(panel)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 10)
    panel.add_child(col)
    col.add_child(_label("🎯 聽一聽，找找看！", 32, DARK, HORIZONTAL_ALIGNMENT_CENTER))
    var target: Dictionary = pokemon[quiz_target]
    var prompt := _pretty_button("🔊 " + str(target["question"]), Color("#E7F8F6"), Vector2(0, 83))
    prompt.pressed.connect(func(): _say(str(target["question"])))
    col.add_child(prompt)
    var row := HBoxContainer.new()
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 12)
    col.add_child(row)
    for i in quiz_options:
        row.add_child(_creature_card(i, _answer.bind(i), Vector2(250, 260)))
    var next := _pretty_button("🌟 換下一題", GOLD, Vector2(0, 68))
    next.pressed.connect(_new_round)
    col.add_child(next)


func _answer(index: int) -> void:
    if quiz_solved:
        _say("答對了！按下面的換下一題，就能繼續玩！")
        return
    if index == quiz_target:
        quiz_solved = true
        selected = index
        _add_heart(index, 2)
        _say("太棒啦！你找到" + str(pokemon[index]["name"]) + "了！送你兩個愛心貼紙。" + str(pokemon[index]["fun"]))
    else:
        _say("再試一次！" + str(pokemon[quiz_target]["question"]))


func _new_round() -> void:
    _next_question()
    _compose()
    _say(str(pokemon[quiz_target]["question"]))


func _show_care() -> void:
    var root := HBoxContainer.new()
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_theme_constant_override("separation", 14)
    content_host.add_child(root)
    var left := _styled_panel(Color(str(pokemon[selected]["color"])).lightened(0.54))
    left.custom_minimum_size = Vector2(415, 0)
    root.add_child(left)
    var left_content := VBoxContainer.new()
    left.add_child(left_content)
    left_content.add_child(_label("💗 我的好朋友", 28, DARK, HORIZONTAL_ALIGNMENT_CENTER))
    left_content.add_child(_picture(selected, 260))
    left_content.add_child(_label(str(pokemon[selected]["name"]), 34, DARK, HORIZONTAL_ALIGNMENT_CENTER))
    left_content.add_child(_label("🌟 收集到 %d 個愛心" % _heart_count(selected), 22, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
    var selector := _pretty_button("🔄 換一個朋友", WHITE, Vector2(0, 58))
    selector.pressed.connect(_switch_care_friend)
    left_content.add_child(selector)
    var right := _styled_panel(WHITE)
    right.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.add_child(right)
    var actions := VBoxContainer.new()
    actions.add_theme_constant_override("separation", 13)
    right.add_child(actions)
    actions.add_child(_label("想跟朋友做什麼？", 28))
    var care_actions = [
        ["🍎 給牠吃點心", "哇，好好吃的點心，謝謝你！"],
        ["🪁 一起玩耍", "一起跳一跳、動一動！玩耍真開心！"],
        ["💤 休息一下", "舒服地休息一下，等一下又有精神囉！"],
        ["🫶 輕輕打招呼", "你好呀！謝謝你今天來陪我。"],
    ]
    for action in care_actions:
        var button := _pretty_button(str(action[0]), Color("#EAF9F1"), Vector2(0, 80))
        button.pressed.connect(_care_play.bind(str(action[1])))
        actions.add_child(button)


func _switch_care_friend() -> void:
    selected = (selected + 1) % pokemon.size()
    _compose()
    _say("現在換" + str(pokemon[selected]["name"]) + "來玩！" + str(pokemon[selected]["intro"]))


func _care_play(action_text: String) -> void:
    _add_heart(selected)
    _compose()
    _say(str(pokemon[selected]["name"]) + "說：" + action_text + " 又得到一顆愛心！")


func _show_stickers() -> void:
    var panel := _styled_panel(WHITE)
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content_host.add_child(panel)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 7)
    panel.add_child(col)
    var total := 0
    for v in hearts.values():
        total += int(v)
    col.add_child(_label("🌟 我的寶可夢愛心貼紙：%d 顆" % total, 30, DARK, HORIZONTAL_ALIGNMENT_CENTER))
    col.add_child(_label("點一下喜歡的朋友，就能再聽牠說話！", 19, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
    var grid := GridContainer.new()
    grid.columns = 6
    grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 5)
    col.add_child(grid)
    for i in range(pokemon.size()):
        var cell := VBoxContainer.new()
        cell.custom_minimum_size = Vector2(123, 195)
        cell.add_child(_creature_card(i, _select_sticker.bind(i), Vector2(113, 137)))
        cell.add_child(_label("💗 %d" % _heart_count(i), 21, DARK, HORIZONTAL_ALIGNMENT_CENTER))
        grid.add_child(cell)
    col.add_child(_label("沒有輸贏壓力。多聽一次、多玩一次，就能慢慢收集貼紙。", 19, MUTED, HORIZONTAL_ALIGNMENT_CENTER))


func _select_sticker(index: int) -> void:
    selected = index
    _add_heart(index)
    _compose()
    _say(str(pokemon[index]["intro"]))


func _replay() -> void:
    if last_speech.is_empty():
        _say(str(pokemon[selected]["intro"]))
    else:
        _say(last_speech)
