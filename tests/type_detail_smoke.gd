extends SceneTree
## Verify bold clickable Pokemon type badges, large elemental icons,
## colorful weakness and strengths, screen-size safety, audio and English UI.
const Rules=preload("res://scripts/PokemonBattleRules.gd")

func _initialize() -> void:
    call_deferred("_run")

func _find(node: Node,name_to_find: String) -> Node:
    if node.name==name_to_find:
        return node
    for child in node.get_children():
        var candidate=_find(child,name_to_find)
        if candidate!=null:
            return candidate
    return null

func _run() -> void:
    var had_save=FileAccess.file_exists("user://pokemon_kids_progress.json")
    var backed_up=FileAccess.get_file_as_bytes("user://pokemon_kids_progress.json") if had_save else PackedByteArray()
    for viewport in [Vector2i(1280,720),Vector2i(1024,600)]:
        root.size=viewport
        await process_frame
        var game=load("res://scenes/Main.tscn").instantiate()
        root.add_child(game)
        await process_frame
        await process_frame
        if game.pokemon.size()!=15:
            _fail("All 15 species must be preserved")
            return
        for index in [0,1,12,13,14]:
            game._select_friend(index)
            await process_frame
            await process_frame
            var friend: Dictionary=game.pokemon[index]
            var scroller=game.pokemon_detail_scroll
            if scroller==null:
                _fail("Independent detail scrolling is missing")
                return
            var panel=_find(game,"TypeBadgePanel")
            if panel==null:
                _fail("Prominent type badges should be visible within the detail pane")
                return
            for kind_value in friend["types"]:
                var kind=str(kind_value)
                var badge=_find(game,"TypeBadge_"+kind)
                if badge==null or not badge is Button:
                    _fail("Missing tappable type badge for "+kind)
                    return
                if badge.custom_minimum_size.y<68 or badge.get_theme_font_size("font_size")<27:
                    _fail("Type icon buttons are too small for preschool fingers")
                    return
                if badge.get_global_rect().end.y>game.pokemon_detail_scroll.get_global_rect().end.y+270:
                    _fail("Attribute badge should be near the top, not buried below content")
                    return
                var list_before=game.pokemon_roster_scroll.scroll_vertical
                var detail_before=scroller.scroll_vertical
                badge.pressed.emit()
                await process_frame
                var overlay=game.type_detail_popup
                if overlay==null or overlay.focused_type!=kind:
                    _fail("Clicking the "+kind+" badge must open its matching details")
                    return
                if _find(overlay,"LargeTypeIcon")==null or not _find(overlay,"LargeTypeIcon") is Label:
                    _fail("A large type icon must appear in the opened popup")
                    return
                var symbol=_find(overlay,"LargeTypeIcon")
                if symbol.get_theme_font_size("font_size")<68:
                    _fail("The detail icon must be substantially larger than the type badges")
                    return
                if symbol.text!=Rules.icon(kind):
                    _fail("Popup icon must match the selected elemental type")
                    return
                var modal=_find(overlay,"TypeDetailDialog")
                var viewport_rect=game.get_global_rect()
                var modal_rect=modal.get_global_rect()
                if modal_rect.position.x<viewport_rect.position.x-2 or modal_rect.end.x>viewport_rect.end.x+2 or modal_rect.position.y<viewport_rect.position.y-2 or modal_rect.end.y>viewport_rect.end.y+2:
                    _fail("Type detail dialog must remain inside compact landscape")
                    return
                var explanation=overlay.narration()
                if not explanation.contains(kind) or explanation.length()<24:
                    _fail("Type explanation should be meaningful and narratable for "+kind)
                    return
                var weakness=Rules.weaknesses(friend["types"])
                if weakness.size()>0:
                    var found_one=false
                    for weak in weakness:
                        if _find(overlay,"SmallType_"+str(weak))!=null:
                            found_one=true
                            break
                    if not found_one:
                        _fail("Weaknesses must be illustrated with colorful icons")
                        return
                if game.pokemon_roster_scroll.is_processing_input() or scroller.is_processing_input():
                    _fail("Underlying swipe areas must be disabled while the dialog is open")
                    return
                var speak=_find(overlay,"SpeakTypeDetail")
                if speak==null:
                    _fail("The popup needs a large voice narration button")
                    return
                speak.pressed.emit()
                if game.last_speech!=explanation:
                    _fail("Popup narration must explain its type and strengths")
                    return
                var close=_find(overlay,"CloseTypeDetail")
                close.pressed.emit()
                await process_frame
                if game.type_detail_popup!=null:
                    _fail("The type detail window must close using the obvious X button")
                    return
                if not game.pokemon_roster_scroll.is_processing_input() or not scroller.is_processing_input():
                    _fail("Roster/detail touch scrolling must resume after closing popup")
                    return
                if abs(game.pokemon_roster_scroll.scroll_vertical-list_before)>2 or abs(scroller.scroll_vertical-detail_before)>2:
                    _fail("Opening a type card must not reset the Pokedex scroll positions")
                    return
        game._change_mode(5)
        game._change_button_language("en")
        await process_frame
        game._change_mode(0)
        await process_frame
        var english_badge=_find(game,"TypeBadge_"+str(game.pokemon[game.selected]["types"][0]))
        english_badge.pressed.emit()
        await process_frame
        var english_popup=game.type_detail_popup
        if english_popup==null or not str(_find(english_popup,"SpeakTypeDetail").text).contains("Listen"):
            _fail("Type-detail buttons must respect the English button language setting")
            return
        if not str(_find(english_popup,"DoneTypeDetail").text).contains("Back"):
            _fail("Type-detail back button should be English when English is selected")
            return
        game._close_type_detail()
        game.queue_free()
        await process_frame
    if had_save:
        var restored=FileAccess.open("user://pokemon_kids_progress.json",FileAccess.WRITE)
        restored.store_buffer(backed_up)
        restored.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path("user://pokemon_kids_progress.json"))
    print("PASS: 15 Pokemon large tappable type badges, animated modal-sized icon, weaknesses, voice, English and independent touch scroll")
    quit(0)

func _fail(reason: String) -> void:
    push_error("POKEMON TYPE DETAILS FAILED: "+reason)
    quit(1)
