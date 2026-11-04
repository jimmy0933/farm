extends SceneTree
## Regression: a 4-year-old must swipe the Pokemon roster, read the detail
## panel independently, use up/down buttons, and keep scroll after selection.
const TouchScroll=preload("res://scripts/KidsTouchScroll.gd")

func _initialize() -> void:
    call_deferred("_run")

func _range(scroller: ScrollContainer) -> int:
    return maxi(0,roundi(scroller.get_v_scroll_bar().max_value-scroller.get_v_scroll_bar().page))

func _named(parent: Node,key: String) -> Node:
    if parent.name==key:
        return parent
    for child in parent.get_children():
        var r=_named(child,key)
        if r!=null:
            return r
    return null

func _run() -> void:
    var saved_exists=FileAccess.file_exists("user://pokemon_kids_progress.json")
    var saved_bytes=FileAccess.get_file_as_bytes("user://pokemon_kids_progress.json") if saved_exists else PackedByteArray()
    for viewport_size in [Vector2i(1280,720),Vector2i(1024,600)]:
        root.size=viewport_size
        await process_frame
        var main=load("res://scenes/Main.tscn").instantiate()
        root.add_child(main)
        await process_frame
        await process_frame
        var roster=main.pokemon_roster_scroll
        var details=main.pokemon_detail_scroll
        if not roster is TouchScroll or not details is TouchScroll:
            _fail("Both Pokedex panes must use independent KidsTouchScroll controls")
            return
        if main.content_scroller.vertical_scroll_mode!=ScrollContainer.SCROLL_MODE_DISABLED:
            _fail("Outer Pokedex scroller must not steal finger gestures from two panels")
            return
        if _range(roster)<80:
            _fail("Roster is still stretched too tall to actually scroll: "+str(_range(roster)))
            return
        if _range(details)<20:
            _fail("Details cannot scroll independently: "+str(_range(details)))
            return
        for name in ["PokemonRosterPanel","PokemonDetailPanel","RosterPageUp","RosterPageDown","DetailPageUp","DetailPageDown"]:
            if _named(main,name)==null:
                _fail("Missing independent pane or kid-friendly paging control "+name)
                return
        var full=main.content_scroller.get_global_rect()
        if roster.get_global_rect().end.y>full.end.y+3.0 or details.get_global_rect().end.y>full.end.y+3.0:
            _fail("One of the panels overflows the fixed voice footer")
            return
        if roster.get_global_rect().intersects(details.get_global_rect()):
            _fail("Roster and detail touch targets overlap")
            return
        var old_detail=int(details.scroll_vertical)
        roster._begin(330.0)
        roster._drag(219.0,0.0)
        if not roster.was_dragging or roster.scroll_vertical<90:
            _fail("Single-finger roster drag does not scroll quickly enough")
            return
        if details.scroll_vertical!=old_detail:
            _fail("Dragging roster must not scroll Pokemon details")
            return
        var before_select=main.selected
        main._select_friend((before_select+1)%main.pokemon.size())
        if main.selected!=before_select:
            _fail("Swiping a character card should not accidentally select it")
            return
        roster._end()
        var hold=roster.scroll_vertical
        roster._begin(350.0)
        roster._end()
        var new_selected=(before_select+1)%main.pokemon.size()
        main._select_friend(new_selected)
        await process_frame
        await process_frame
        if main.selected!=new_selected:
            _fail("A deliberate tap must still select the Pokemon")
            return
        if abs(main.pokemon_roster_scroll.scroll_vertical-hold)>4:
            _fail("Character selection must keep the left roster scroll position")
            return
        roster=main.pokemon_roster_scroll
        details=main.pokemon_detail_scroll
        details._begin(330.0)
        details._drag(230.0,0.0)
        if not details.was_dragging or details.scroll_vertical<25:
            _fail("Finger drag fails on the character details pane")
            return
        if abs(roster.scroll_vertical-hold)>4:
            _fail("Detail swipe must not move the left roster")
            return
        details._end()
        var detail_was=details.scroll_vertical
        var detail_down=_named(main,"DetailPageDown")
        var detail_up=_named(main,"DetailPageUp")
        detail_up.pressed.emit()
        if details.scroll_vertical>=detail_was:
            _fail("One-tap detail up button must actually move the content")
            return
        detail_down.pressed.emit()
        if details.scroll_vertical<=0:
            _fail("One-tap detail down button must move content forward")
            return
        var roster_up=_named(main,"RosterPageUp")
        var roster_down=_named(main,"RosterPageDown")
        roster_up.pressed.emit()
        if roster.scroll_vertical>=hold:
            _fail("One-tap roster up button does not page upward")
            return
        roster_down.pressed.emit()
        if roster.scroll_vertical<=0:
            _fail("One-tap roster down button does not page forward")
            return
        main._change_mode(4)
        await process_frame
        var battle=main.battle_view
        var picker=_named(battle,"BattleSelectionScroll")
        if not picker is TouchScroll or picker.swipe_speed<1.8:
            _fail("Battle opponent selection must also support fast finger swipe")
            return
        if _range(picker)<20:
            _fail("Battle selection grid must be scrollable on compact landscape")
            return
        if _named(battle,"BattlePageDown")==null or _named(battle,"BattlePageUp")==null:
            _fail("Battle picker needs accessible large up/down page buttons")
            return
        var before=battle.player_index
        picker._begin(290.0)
        picker._drag(190.0,0.0)
        battle._choose_from_list(0)
        if battle.player_index!=before:
            _fail("Dragging a battle character must not count as a tap")
            return
        picker._end()
        picker._begin(280.0)
        picker._end()
        battle._choose_from_list(0)
        if battle.player_index!=0:
            _fail("Normal taps must still pick a battle Pokemon")
            return
        main.queue_free()
        await process_frame
    if saved_exists:
        var f=FileAccess.open("user://pokemon_kids_progress.json",FileAccess.WRITE)
        f.store_buffer(saved_bytes)
        f.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path("user://pokemon_kids_progress.json"))
    print("PASS: independent Pokedex roster/details swipe, paging, position retention and battle character swipe on both landscape sizes")
    quit(0)

func _fail(reason: String) -> void:
    push_error("POKEMON SCROLL FAILED: "+reason)
    quit(1)
