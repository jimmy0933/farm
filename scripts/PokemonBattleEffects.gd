extends Control
## A single animated overlay above the landscape and below the battle HUD.
## Three clear phases: charge, flying projectile and sparkling impact. No strobing.
const Rules=preload("res://scripts/PokemonBattleRules.gd")
var active: bool=false
var age: float=0.0
const NORMAL_DURATION: float=1.35
const STRONG_DURATION: float=1.82
const HIT_FRACTION: float=.71
var duration: float=NORMAL_DURATION
var strong_move: bool=false
var impact_started: bool=false
var element: String="一般"
var player_attacking: bool=true
var damage: int=0
var efficacy: float=1.0

func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    set_process(false)

func trigger(kind: String, from_player: bool, amount: int, effectiveness: float, strong: bool=false) -> void:
    element=kind
    strong_move=strong
    duration=STRONG_DURATION if strong else NORMAL_DURATION
    impact_started=false
    player_attacking=from_player
    damage=amount
    efficacy=effectiveness
    age=0.0
    active=true
    set_process(true)
    queue_redraw()

func _process(delta: float) -> void:
    age+=delta
    if not impact_started and age>=duration*HIT_FRACTION:
        impact_started=true
        _damage_popup()
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
    tw.tween_property(label,"position",label.position+Vector2(0,-56),.95)
    tw.tween_property(label,"modulate:a",0.0,.95)
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
    var strength=1.24 if strong_move else 1.0
    var color=Rules.type_color(element)
    var aura=color.lerp(Color.WHITE,.43)
    # Stage 1: a large, breathing, layered elemental power-up circle.
    if progress<.25:
        var phase=progress/.25
        var pulse=sin(phase*PI*.9)
        var charge_radius=(28.0+phase*42.0)*strength
        _circle(from,charge_radius*1.23,Color(aura,.06+.12*pulse))
        draw_arc(from,charge_radius,0,TAU,64,Color(color,.65),6.0,true)
        draw_arc(from,charge_radius*.76,0,TAU,64,Color(Color.WHITE,.68),3.3,true)
        for i in range(16):
            var angle=TAU*float(i)/16.0+phase*1.8
            var r=charge_radius*(1.10+float(i%3)*.2)
            var particle=from+Vector2(cos(angle),sin(angle))*r
            _star(particle,(4.5+float(i%3)*2.0)*strength,Color("#FFFFFF",.55+.35*pulse))
        draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
        return
    var flying=progress< HIT_FRACTION
    var travel=clampf((progress-.25)/(HIT_FRACTION-.25),0.0,1.0)
    travel=travel*travel*(3.0-2.0*travel)
    var projectile=from.lerp(toward,travel) if flying else toward
    var opacity=1.0 if flying else maxf(0.0,1.0-(progress-HIT_FRACTION)/(1.0-HIT_FRACTION))
    if flying:
        # Thick transparent tail, thin white streak, spark clusters.
        for i in range(9):
            var fade=float(i)/9.0
            var position=from.lerp(projectile,fade)
            _circle(position,(15.0+fade*7.0)*strength,Color(color,(.09+.15*fade)*travel))
        draw_line(from,projectile,Color(aura,.28),19.0*strength,true)
        draw_line(from,projectile,Color(Color.WHITE,.55),3.5*strength,true)
    var orbit=37.0*strength
    if element=="電":
        var points=PackedVector2Array([from])
        for i in range(1,11):
            var t=float(i)/11.0
            var base=from.lerp(projectile,t)
            base+=Vector2(0,sin(float(i)*2.4+age*17.0)*25.0*strength)
            points.append(base)
        points.append(projectile)
        draw_polyline(points,Color("#FFE99C",opacity*.9),15.0*strength,true)
        draw_polyline(points,Color("#FFFFFF",opacity),4.0*strength,true)
        for i in range(17):
            var a=TAU*float(i)/17.0+age*5.2
            _star(projectile+Vector2(cos(a),sin(a))*orbit,7.0*strength,Color("#FFF0A0",opacity))
    elif element=="水" or element=="冰":
        for i in range(17):
            var angle=TAU*float(i)/17.0+age*2.2
            var r=20.0+float(i%4)*10.0
            var p=projectile+Vector2(cos(angle)*r,sin(angle)*r*.83)
            _circle(p,(9.0+float(i%4)*2.0)*strength,Color("#8FE2F9",opacity*.82))
            _circle(p-Vector2(3,5),3.0,Color("#FFFFFF",opacity))
        if not flying:
            draw_arc(toward,35.0+(progress-HIT_FRACTION)*275.0,0,TAU,64,Color("#DAF9FF",opacity),8.0,true)
    elif element=="火":
        for i in range(19):
            var theta=TAU*float(i)/19.0+age*3.0
            var radius=16.0+float(i%5)*8.0
            var p=projectile+Vector2(cos(theta)*radius,sin(theta)*radius)
            _circle(p,(7.0+float(i%4)*3.0)*strength,Color("#FF9B50",opacity))
            _circle(p-Vector2(0,3),4.0,Color("#FFF0AB",opacity))
    elif element=="草" or element=="蟲":
        for i in range(23):
            var angle=TAU*float(i)/23.0+age*4.0
            var r=19.0+float(i%5)*10.0
            var p=projectile+Vector2(cos(angle)*r,sin(angle)*r*.83)
            _leaf(p,.82*strength,angle+.55,Color("#8ED57E",opacity))
        _circle(projectile,23,Color("#F3FFC9",opacity*.6))
    elif element=="幽靈" or element=="毒" or element=="超能力" or element=="惡":
        for scale_factor in [1.9,1.35,.9]:
            _circle(projectile,30.0*scale_factor*strength,Color("#B88DDB",opacity*.11))
        _circle(projectile,28.0*strength,Color("#9D72D2",opacity*.81))
        _circle(projectile,13.0*strength,Color("#F5E1FD",opacity))
        for i in range(16):
            var angle=TAU*float(i)/16.0+age*5.8
            var p=projectile+Vector2(cos(angle)*58.0,sin(angle)*42.0)
            _circle(p,7.0*strength,Color("#DFC0F7",opacity))
    else:
        for i in range(16):
            var a=TAU*float(i)/16.0+age*.8
            var p=projectile+Vector2(cos(a)*46.0,sin(a)*39.0)
            _star(p,10.0*strength,Color("#FFF2CB",opacity))
        _circle(projectile,19,Color("#FFFFFF",opacity*.77))
    # Stage 3: translucent expanding rings and a soft shower of stars.
    if not flying:
        var impact=clampf((progress-HIT_FRACTION)/(1.0-HIT_FRACTION),0,1)
        for ring in range(3):
            var radius=(23.0+impact*175.0+float(ring)*31.0)*strength
            draw_arc(toward,radius,0,TAU,64,Color(aura,opacity*(.8-float(ring)*.14)),(8.0-float(ring)*2.0),true)
        for i in range(27):
            var theta=TAU*float(i)/27.0+float(i%3)*.2
            var distance=(25.0+impact*(78.0+float(i%5)*17.0))*strength
            var p=toward+Vector2(cos(theta),sin(theta))*distance
            _star(p,(6.0+float(i%3)*2.4)*strength,Color("#FFFFFF",opacity*.96))
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
