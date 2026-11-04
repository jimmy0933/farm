extends ScrollContainer
## One-finger scroll that remains responsive when child cards are Buttons.
## Receives raw touch motion before the GUI dispatch can swallow screen drags.
## Each panel owns its own independent drag and kinetic scrolling state.
@export var swipe_speed: float=1.85

var tracked_finger: int=-1
var tracking_mouse: bool=false
var was_dragging: bool=false
var start_y: float=0.0
var start_scroll: int=0
var last_velocity: float=0.0
var kinetic_velocity: float=0.0
var active_drag: bool=false

func _ready() -> void:
    # We implement phone drag explicitly so parent/child scroll containers
    # cannot both try to handle the same touch.
    scroll_deadzone=100000
    horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
    mouse_filter=Control.MOUSE_FILTER_PASS
    get_v_scroll_bar().custom_minimum_size.x=18
    set_process(false)

func _inside(screen_position: Vector2) -> bool:
    if not is_visible_in_tree():
        return false
    var local=get_global_transform_with_canvas().affine_inverse()*screen_position
    return Rect2(Vector2.ZERO,size).has_point(local)

func _scroll_limit() -> int:
    var bar=get_v_scroll_bar()
    return maxi(0,roundi(bar.max_value-bar.page))

func _begin(at_y: float) -> void:
    start_y=at_y
    start_scroll=scroll_vertical
    was_dragging=false
    last_velocity=0.0
    kinetic_velocity=0.0
    active_drag=true
    set_process(false)

func _drag(at_y: float,velocity: float=0.0) -> void:
    if not active_drag:
        return
    var move=at_y-start_y
    if absf(move)>8.0:
        was_dragging=true
    if not was_dragging:
        return
    scroll_vertical=clampi(roundi(float(start_scroll)-move*swipe_speed),0,_scroll_limit())
    last_velocity=velocity

func _end() -> void:
    if not active_drag:
        return
    active_drag=false
    if was_dragging and absf(last_velocity)>90.0:
        kinetic_velocity=-last_velocity*swipe_speed*.65
        set_process(true)

func _process(delta: float) -> void:
    if absf(kinetic_velocity)<36.0:
        kinetic_velocity=0.0
        set_process(false)
        return
    var next=clampi(roundi(float(scroll_vertical)+kinetic_velocity*delta),0,_scroll_limit())
    if next==scroll_vertical and (scroll_vertical==0 or scroll_vertical==_scroll_limit()):
        kinetic_velocity=0.0
        set_process(false)
        return
    scroll_vertical=next
    kinetic_velocity*=pow(.08,delta)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and tracked_finger==-1 and _inside(event.position):
            tracked_finger=event.index
            tracking_mouse=false
            _begin(event.position.y)
        elif not event.pressed and tracked_finger==event.index:
            tracked_finger=-1
            _end()
    elif event is InputEventScreenDrag:
        if tracked_finger==event.index and active_drag:
            _drag(event.position.y,event.velocity.y)
    elif tracked_finger==-1 and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
        if event.pressed and _inside(event.position):
            tracking_mouse=true
            _begin(event.position.y)
        elif not event.pressed and tracking_mouse:
            tracking_mouse=false
            _end()
    elif tracked_finger==-1 and tracking_mouse and event is InputEventMouseMotion:
        if active_drag and (event.button_mask&MOUSE_BUTTON_MASK_LEFT)!=0:
            _drag(event.position.y,event.relative.y*60.0)

func page(direction: int) -> void:
    kinetic_velocity=0.0
    set_process(false)
    scroll_vertical=clampi(scroll_vertical+direction*maxi(100,roundi(size.y*.84)),0,_scroll_limit())

func restore(offset: int) -> void:
    kinetic_velocity=0.0
    set_process(false)
    scroll_vertical=clampi(offset,0,_scroll_limit())
