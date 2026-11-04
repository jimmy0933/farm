extends Control
## A single animated overlay above the landscape and below the battle HUD.
## No gore, shaking camera or strobing flashes. 0.72s friendly effects.
const Rules=preload("res://scripts/PokemonBattleRules.gd")
var active: bool=false
var age: float=0.0
var duration: float=.77
var element: String="一般"
var player_attacking: bool=true
var damage: int=0
var efficacy: float=1.0

func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    set_process(false)

func trigger(kind: String, from_player: bool, amount: int, effectiveness: float) -> void:
    element=kind
    player_attacking=from_player
    damage=amount
    efficacy=effectiveness
    age=0.0
    active=true
    set_process(true)
    _damage_popup()
    queue_redraw()

func _process(delta: float) -> void:
    age+=delta
    if age>=duration:
        active=false
        set_process(false)
    queue_redraw()

func _circle(center: Vector2, radius: float, color: Color) -> void:
    draw_circle(center,radius,color)

func _star(center: Vector2,radius: float,color: Color) -> void:
    var points=PackedVector2Array()
    for i in range(10):
        var theta=float(i)*TAU/10.0-PI*.5
        var r=radius if i%2==0 else radius*.4
        points.append(center+Vector2(cos(theta)*r,sin(theta)*r))
    draw_colored_polygon(points,color)

func _leaf(p: Vector2,s: float,angle: float,color: Color) -> void:
    var forward=Vector2(cos(angle),sin(angle))
    var normal=Vector2(-forward.y,forward.x)
    draw_colored_polygon(PackedVector2Array([
        p-forward*12*s,p+normal*7*s,p+forward*17*s,p-normal*7*s]),color)
    draw_line(p-forward*10*s,p+forward*12*s,color.darkened(.3),1.5,true)

func _damage_popup() -> void:
    var label=Label.new()
    label.text="🛡️ 0" if damage<=0 else ("🌟 -%d" % damage if efficacy>1.0 else "-%d" % damage)
    label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size",32)
    label.add_theme_color_override("font_color",Color("#FFF4B9") if efficacy>1.0 else Color.WHITE)
    label.add_theme_color_override("font_outline_color",Color("#31445D"))
    label.add_theme_constant_override("outline_size",5)
    label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    label.custom_minimum_size=Vector2(125,50)
    add_child(label)
    var spot=Vector2(.75,.21) if player_attacking else Vector2(.23,.38)
    label.position=size*spot-Vector2(60,10)
    label.pivot_offset=Vector2(65,28)
    label.scale=Vector2(.82,.82)
    var tw=create_tween()
    tw.set_parallel(true)
    tw.tween_property(label,"position",label.position+Vector2(0,-40),.75)
    tw.tween_property(label,"modulate:a",0.0,.75)
    tw.tween_property(label,"scale",Vector2(1.12,1.12),.3).set_trans(Tween.TRANS_BACK)
    tw.finished.connect(func():
        if is_instance_valid(label):
            label.queue_free()
    )

func _draw() -> void:
    if not active or size.x<=0.0 or size.y<=0.0:
        return
    draw_set_transform(Vector2.ZERO,0.0,Vector2(size.x/1000.0,size.y/480.0))
    var progress=clampf(age/duration,0.0,1.0)
    var from=Vector2(302,305) if player_attacking else Vector2(748,176)
    var toward=Vector2(748,179) if player_attacking else Vector2(302,300)
    var traveling=clampf(progress*1.8,0.0,1.0)
    var projectile=from.lerp(toward,traveling)
    var color=Rules.type_color(element)
    var opacity=maxf(0.0,1.0-progress*.84)
    if element=="電":
        # Soft zigzag lightning and scattered glowing sparkles.
        var points=PackedVector2Array([from])
        for i in range(1,7):
            var t=float(i)/7.0
            var base=from.lerp(projectile,t)
            base+=Vector2(0,sin(float(i)*2.6+age*12.0)*22.0)
            points.append(base)
        points.append(projectile)
        draw_polyline(points,Color("#FFF6B0",opacity),10.0,true)
        draw_polyline(points,Color("#FFFFFF",opacity),3.0,true)
        for i in range(9):
            var theta=float(i)*TAU/9.0+age*6.0
            _star(projectile+Vector2(cos(theta),sin(theta))*29.0,5.0,Color("#FFEEA5",opacity))
    elif element=="水" or element=="冰":
        for i in range(8):
            var offset=Vector2(cos(float(i)*2.4),sin(float(i)*2.4))*float(12+i%3*7)
            _circle(projectile+offset,12.0 if element=="水" else 8.0,Color("#7CD3EF",opacity))
            _circle(projectile+offset-Vector2(3,5),4,Color("#E6FBFF",opacity))
        if progress>.4:
            draw_arc(toward,42.0+progress*31.0,0,TAU,52,Color("#D3F8FA",opacity),6,true)
    elif element=="火":
        for i in range(12):
            var theta=float(i)*TAU/12.0
            var radius=12.0+float(i%4)*5.0
            var p=projectile+Vector2(cos(theta)*radius,sin(theta)*radius)
            _circle(p,7.0+float(i%3)*2.0,Color("#FFA866",opacity))
            _circle(p-Vector2(1,3),3.0,Color("#FFF2B9",opacity))
    elif element=="草" or element=="蟲":
        for i in range(13):
            var p=projectile+Vector2(cos(float(i)*2.25)*35.0,sin(float(i)*2.25)*27.0)
            _leaf(p,.72,float(i)*.65+progress*4.0,Color("#79C47C",opacity))
        _circle(projectile,17,Color("#E7F9B8",opacity*.5))
    elif element=="幽靈" or element=="毒" or element=="超能力" or element=="惡":
        _circle(projectile,41,Color("#B28DDC",opacity*.18))
        _circle(projectile,26,Color("#A992D7",opacity*.7))
        _circle(projectile,15,Color("#F4D8FA",opacity*.86))
        for i in range(7):
            var theta=float(i)*TAU/7.0+progress*6.0
            var p=projectile+Vector2(cos(theta)*48.0,sin(theta)*35.0)
            _circle(p,7.5,Color("#D6B6F3",opacity))
    else:
        for i in range(9):
            var theta=float(i)*TAU/9.0+age*.8
            var p=projectile+Vector2(cos(theta)*34.0,sin(theta)*31.0)
            _star(p,9.0,Color("#FFF2CB",opacity))
        _circle(projectile,14,Color("#FFFFFF",opacity*.65))
    if progress>.35:
        var impact=clampf((progress-.35)/.65,0,1)
        var ring_radius=24.0+impact*92.0
        draw_arc(toward,ring_radius,0,TAU,48,Color(color,opacity*.66),4.0,true)
        for i in range(9):
            var a=float(i)*TAU/9.0
            var p=toward+Vector2(cos(a),sin(a))*ring_radius*.75
            _star(p,4.5,Color("#FFFFFF",opacity*.73))
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
