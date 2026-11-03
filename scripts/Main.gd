extends Control
## APK-derived editable reconstruction starter. No original .gdc source has been recovered.
const Portrait = preload("res://scripts/CreaturePortrait.gd")
const RaceStage = preload("res://scripts/RaceStage.gd")
const PaintBoard = preload("res://scripts/PaintBoard.gd")
const INK := Color("#24463e")
const SOFT := Color("#fdf9e9")
const ACCENT := Color("#f8c76d")
const GREEN := Color("#d7eed9")
const BG := Color("#ecf6e8")

var animals: Array = []
var birds: Array = []
var monsters: Array = []
var pokemon: Array = []
var levels: Array = []
var saved: Dictionary = {"known": [], "adopted": [], "quiz": 0, "garden": []}
var page: VBoxContainer
var subtitle_label: Label
var current_screen: String = "home"

func _ready() -> void:
	animals = _load_records("res://data/animals.json")
	birds = _load_records("res://data/birds.json")
	monsters = _load_records("res://data/monsters.json")
	pokemon = _load_records("res://data/pokemon.json")
	levels = _load_records("res://data/levels.json")
	_load_save()
	_show_home()

func _load_records(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("資料載入失敗：" + path)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Array else []

func _load_save() -> void:
	if not FileAccess.file_exists("user://farm_rebuild_save.json"):
		return
	var file := FileAccess.open("user://farm_rebuild_save.json", FileAccess.READ)
	if file != null:
		var obj: Variant = JSON.parse_string(file.get_as_text())
		if obj is Dictionary:
			for key in saved.keys():
				if obj.has(key):
					saved[key] = obj[key]

func _save() -> void:
	var file := FileAccess.open("user://farm_rebuild_save.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(saved, "  "))

func _style(bg_color: Color, radius: int = 22, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border
	if border != Color.TRANSPARENT:
		style.set_border_width_all(2)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _label(value: String, font_size: int = 25, color: Color = INK) -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return item

func _button(value: String, action: Callable, fill: Color = ACCENT, min_height: int = 54) -> Button:
	var b := Button.new()
	b.text = value
	b.custom_minimum_size = Vector2(0, min_height)
	b.add_theme_font_size_override("font_size", 23)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_stylebox_override("normal", _style(fill))
	b.add_theme_stylebox_override("hover", _style(fill.lightened(0.12)))
	b.add_theme_stylebox_override("pressed", _style(fill.darkened(0.07)))
	b.pressed.connect(action)
	return b

func _screen(title: String, description: String = "", mode: String = "") -> void:
	current_screen = mode
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	margin.add_child(outer)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	outer.add_child(header)
	if mode != "home":
		header.add_child(_button("〈 首頁", _show_home, GREEN, 52))
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	titles.add_child(_label(title, 35))
	if description != "":
		var sub := _label(description, 18, Color("#647e6e"))
		titles.add_child(sub)
	var stats := _label("已認識 %d 位朋友" % (saved["known"] as Array).size(), 19)
	header.add_child(stats)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	page = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	scroll.add_child(page)

func _show_home() -> void:
	_screen("動物探險島", "一起探索、照顧動物，發現新朋友", "home")
	var intro := PanelContainer.new()
	intro.add_theme_stylebox_override("panel", _style(Color("#fff4cf")))
	page.add_child(intro)
	intro.add_child(_label("歡迎來到農場！  探險、蒐集、學習與遊戲都在這裡。", 25))
	var options := [
		["🐄 農場樂園", "farm"], ["🌳 森林樂園", "forest"],
		["🦋 昆蟲樂園", "insect"], ["🐬 海底樂園", "ocean"],
		["🦁 動物園樂園", "zoo"], ["🐦 鳥類樂園", "bird"],
		["✨ 怪獸樂園", "monster"], ["⚡ 寶可夢樂園", "pokemon"],
		["🏡 私人農場", "private_farm"], ["🌱 我的開心農田", "garden"],
		["🏎️ 動物賽車場", "race"], ["🪽 鳥類飛行大賽", "bird_race"],
		["📚 動物圖鑑", "all"], ["🎯 學習關卡", "quiz"],
		["🎨 畫畫學堂", "paint"]
	]
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	page.add_child(grid)
	for i in range(options.size()):
		var entry: Array = options[i]
		var category: String = entry[1]
		var c := _button(entry[0], _open_category.bind(category), Color("#e5f1da") if i % 3 != 1 else Color("#fce4c2"), 100)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(c)
	var note := _label("此版本是 APK 資料重建版，並非原版程式碼逐行還原。", 18, Color("#6c8479"))
	page.add_child(note)

func _open_category(kind: String) -> void:
	match kind:
		"pokemon": _show_collection("寶可夢樂園", pokemon, "pokemon")
		"bird": _show_collection("鳥類樂園", birds, "bird")
		"monster": _show_collection("怪獸樂園", monsters, "monster")
		"private_farm": _show_private_farm()
		"garden": _show_garden()
		"race", "bird_race": _show_race(kind)
		"quiz": _show_quiz()
		"paint": _show_paint()
		"all": _show_collection("動物圖鑑", animals + birds + monsters + pokemon, "all")
		_: 
			var items := animals.filter(func(row: Dictionary) -> bool: return str(row.get("zone", "")) == kind)
			_show_collection({"farm":"農場樂園", "forest":"森林樂園", "zoo":"動物園樂園", "insect":"昆蟲樂園", "ocean":"海底樂園"}.get(kind, "探索樂園"), items, kind)

func _show_collection(title: String, records: Array, category: String) -> void:
	_screen(title, "點選朋友查看介紹與互動", category)
	if records.is_empty():
		page.add_child(_label("目前沒有資料。"))
		return
	if category == "pokemon":
		var all_types: Array[String] = ["全部屬性"]
		for record in records:
			for kind in record.get("types", []):
				if not all_types.has(str(kind)):
					all_types.append(str(kind))
		var selector := OptionButton.new()
		selector.add_theme_font_size_override("font_size", 23)
		for kind in all_types:
			selector.add_item(kind)
		page.add_child(_label("依屬性篩選", 22))
		page.add_child(selector)
		selector.item_selected.connect(func(index: int) -> void:
			_show_filtered_pokemon(all_types[index]))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	page.add_child(grid)
	for record in records:
		if not record is Dictionary:
			continue
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", _style(SOFT, 20))
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(box)
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_child(col)
		var portrait := Portrait.new()
		portrait.configure(record)
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(portrait)
		var name_label := _label(str(record.get("name", "朋友")), 24)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(name_label)
		col.add_child(_button("認識牠", _show_detail.bind(record, category), GREEN, 48))

func _show_filtered_pokemon(kind: String) -> void:
	if kind == "全部屬性":
		_show_collection("寶可夢樂園", pokemon, "pokemon")
		return
	_screen("寶可夢：" + kind, "點選朋友查看詳細介紹", "pokemon_filtered")
	var matching: Array = pokemon.filter(func(record: Dictionary) -> bool:
		return (record.get("types", []) as Array).has(kind))
	var grid := GridContainer.new()
	grid.columns = 4
	page.add_child(grid)
	for creature in matching:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _style(SOFT))
		grid.add_child(panel)
		var content := VBoxContainer.new()
		panel.add_child(content)
		var portrait := Portrait.new()
		portrait.configure(creature)
		content.add_child(portrait)
		content.add_child(_label(str(creature.get("name", "寶可夢")), 23))
		content.add_child(_button("認識牠", _show_detail.bind(creature, "pokemon"), GREEN))
	page.add_child(_button("顯示所有屬性", _open_category.bind("pokemon"), ACCENT))

func _show_detail(record: Dictionary, category: String) -> void:
	var identity := str(record.get("id", ""))
	var name := str(record.get("name", "新朋友"))
	if not (saved["known"] as Array).has(identity):
		(saved["known"] as Array).append(identity)
		_save()
	_screen(name, "動物介紹與互動", "detail")
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(SOFT))
	page.add_child(panel)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 22)
	panel.add_child(layout)
	var portrait := Portrait.new()
	portrait.configure(record)
	portrait.custom_minimum_size = Vector2(250, 260)
	layout.add_child(portrait)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(right)
	right.add_child(_label(name, 38))
	right.add_child(_label(str(record.get("desc", "一起玩吧！")), 26))
	if record.has("food"):
		right.add_child(_label("喜歡的食物：" + str(record.get("food")), 21))
	if record.has("skill"):
		right.add_child(_label("招式：" + str(record.get("skill")), 21))
	if record.has("types"):
		right.add_child(_label("屬性：" + "、".join(PackedStringArray(record.get("types", []))), 21))
		right.add_child(_label("害怕的屬性：" + "、".join(PackedStringArray(record.get("weaknesses", []))), 21))
	if record.has("height_m"):
		right.add_child(_label("身高：%.1f 公尺" % float(record.get("height_m")), 21))
	if record.has("weight_kg"):
		right.add_child(_label("體重：%.1f 公斤" % float(record.get("weight_kg")), 21))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	page.add_child(actions)
	var narration := name + "。" + str(record.get("desc", ""))
	if record.has("types"):
		narration += "。牠的屬性是" + "、".join(PackedStringArray(record.get("types", [])))
		narration += "。害怕的屬性有" + "、".join(PackedStringArray(record.get("weaknesses", [])))
	if record.has("height_m"):
		narration += "。身高" + str(record.get("height_m")) + "公尺"
	if record.has("weight_kg"):
		narration += "。體重" + str(record.get("weight_kg")) + "公斤"
	actions.add_child(_button("🔊 聽介紹", _speak.bind(narration), GREEN))
	actions.add_child(_button("🍎 餵點心", _message.bind(name + "吃得很開心！")))
	actions.add_child(_button("🤗 摸摸牠", _message.bind(name + "向你打招呼！"), GREEN))
	actions.add_child(_button("🏡 帶去農場", _adopt.bind(record)))
	page.add_child(_button("〈 回圖鑑", _open_category.bind(category), GREEN))

func _adopt(record: Dictionary) -> void:
	var identity := str(record.get("id", ""))
	if not (saved["adopted"] as Array).has(identity):
		(saved["adopted"] as Array).append(identity)
		_save()
	_message(str(record.get("name", "朋友")) + "來農場作客囉！")

func _find_creature(identity: String) -> Dictionary:
	for record in animals + birds + monsters + pokemon:
		if str(record.get("id", "")) == identity:
			return record
	return {}

func _show_private_farm() -> void:
	_screen("我的私人農場", "帶喜歡的動物與寶可夢回家", "private_farm")
	page.add_child(_label("已入住 %d 位朋友" % (saved["adopted"] as Array).size(), 27))
	var residents: Array = []
	for identity in saved["adopted"]:
		var creature := _find_creature(str(identity))
		if not creature.is_empty():
			residents.append(creature)
	if residents.is_empty():
		page.add_child(_label("農場還沒有住客。先去各個樂園認識朋友，再按「帶去農場」！"))
	else:
		var grid := GridContainer.new()
		grid.columns = 4
		page.add_child(grid)
		for creature in residents:
			grid.add_child(_button("🌿 " + str(creature.get("name", "朋友")), _show_detail.bind(creature, "private_farm"), GREEN, 75))
	page.add_child(_button("去寶可夢樂園", _open_category.bind("pokemon")))
	page.add_child(_button("去農場樂園", _open_category.bind("farm"), GREEN))

func _show_garden() -> void:
	_screen("我的開心農田", "點一塊田地種下小苗，再點一次收成", "garden")
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	page.add_child(grid)
	for i in range(12):
		var planted: bool = (saved["garden"] as Array).has(i)
		var label_text := "🌻 收成" if planted else "🌱 種植"
		grid.add_child(_button(label_text, _toggle_garden.bind(i), Color("#f7e3aa") if planted else GREEN, 110))

func _toggle_garden(index: int) -> void:
	var plots: Array = saved["garden"]
	if plots.has(index):
		plots.erase(index)
	else:
		plots.append(index)
	_save()
	_show_garden()

func _show_quiz() -> void:
	_screen("學習關卡", "來挑戰原 APK 的動物問答題庫", "quiz")
	if levels.is_empty():
		return
	var idx: int = int(saved["quiz"]) % levels.size()
	var data: Dictionary = levels[idx]
	page.add_child(_label("第 %d / %d 關" % [idx + 1, levels.size()], 24))
	page.add_child(_label(str(data.get("prompt", "選出正確答案")), 32))
	if str(data.get("type", "")) == "sound":
		var sound_creature := _find_creature(str(data.get("animal", "")))
		page.add_child(_button("🔊 聽動物聲音介紹", _speak.bind(str(sound_creature.get("sound", sound_creature.get("name", "朋友")))), GREEN))
	for value in data.get("options", []):
		var option := str(value)
		var creature := _find_creature(option)
		var place_names := {"farm": "農場", "forest": "森林", "ocean": "海洋", "zoo": "動物園", "insect": "昆蟲樂園"}
		var display := str(creature.get("name", place_names.get(option, option)))
		page.add_child(_button(display, _answer_quiz.bind(option, str(data.get("answer", "")))))

func _answer_quiz(option: String, answer: String) -> void:
	if option == answer:
		saved["quiz"] = int(saved["quiz"]) + 1
		_save()
		_show_quiz()
		_message("答對了！下一關也加油！")
	else:
		_message("再試一次！")

func _show_race(kind: String) -> void:
	_screen("鳥類飛行大賽" if kind == "bird_race" else "動物賽車場", "簡易三車道競速重建版，左右移動收集星星", kind)
	var racers: Array = birds if kind == "bird_race" else []
	if kind != "bird_race":
		for id in saved["known"]:
			var creature := _find_creature(str(id))
			if not creature.is_empty():
				racers.append(creature)
	if racers.is_empty():
		racers.append(animals[0])
	page.add_child(_label("選擇參賽角色（已認識的所有動物、昆蟲、怪獸與寶可夢）", 22))
	var roster := OptionButton.new()
	roster.add_theme_font_size_override("font_size", 22)
	for creature in racers:
		roster.add_item(str(creature.get("name", "角色")))
	page.add_child(roster)
	var driver_label := _label("我的選手：" + str(racers[0].get("name", "角色")), 23)
	page.add_child(driver_label)
	var race := RaceStage.new()
	race.driver_name = str(racers[0].get("name", "角色"))
	race.driver_color = Color(str(racers[0].get("color", "#f8c76d")))
	roster.item_selected.connect(func(index: int) -> void:
		if index >= 0 and index < racers.size():
			race.driver_name = str(racers[index].get("name", "角色"))
			driver_label.text = "我的選手：" + race.driver_name
			race.driver_color = Color(str(racers[index].get("color", "#f8c76d")))
			race.queue_redraw())
	race.custom_minimum_size = Vector2(0, 390)
	race.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(race)
	race.start()
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 16)
	page.add_child(controls)
	var left := _button("⬅ 左移", race.steer.bind(-1), GREEN)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(left)
	var right := _button("右移 ➡", race.steer.bind(1), ACCENT)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(right)
	race.finished.connect(_race_result)

func _race_result(stars: int) -> void:
	_message("完成比賽！收集了 %d 顆星星。" % stars)
	page.add_child(_button("再比一次", _open_category.bind(current_screen)))

func _show_paint() -> void:
	_screen("畫畫學堂", "用手指自由繪畫，畫布可清除", "paint")
	var board := PaintBoard.new()
	board.custom_minimum_size = Vector2(0, 410)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.mouse_filter = Control.MOUSE_FILTER_STOP
	page.add_child(board)
	var palettes := HBoxContainer.new()
	page.add_child(palettes)
	for color_hex in ["#f2878c", "#f4b454", "#7dc79d", "#76acd3", "#a28add", "#4d6066"]:
		var color := Color(color_hex)
		palettes.add_child(_button("●", func() -> void: board.brush_color = color, color))
	page.add_child(_button("清除畫布", board.clear_board, GREEN))

func _speak(message: String) -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_stop()
		DisplayServer.tts_speak(message, "", 50, 1.0, 1.0)
	else:
		_message("目前裝置不支援語音播放。")

func _message(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "動物探險島"
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
