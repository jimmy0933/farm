extends Control
## Offline, hand-painted-style layered vector landscapes for preschool battles.
## All five biomes are drawn from procedural shapes, with no network requests.
const BIOMES=["meadow","forest","lakeside","sunset","moonforest"]
const COLORS={
    "meadow":{"top":"#83CEFA","bottom":"#E9F6D4","far":"#A4CFB8","mid":"#77BD86","ground":"#9BD46B","grass":"#529F6D","leaf":"#5CA86E"},
    "forest":{"top":"#6FBDCA","bottom":"#E6EAC4","far":"#82B1A2","mid":"#5A9E78","ground":"#85BC6A","grass":"#377E5E","leaf":"#448A63"},
    "lakeside":{"top":"#88CDEB","bottom":"#FFE5B8","far":"#A3C8B5","mid":"#7DBCAA","ground":"#C3D99A","grass":"#5A9C80","leaf":"#65A88A"},
    "sunset":{"top":"#7165B1","bottom":"#FFC79B","far":"#CE9DAD","mid":"#B68099","ground":"#E4B17B","grass":"#B67A75","leaf":"#996F84"},
    "moonforest":{"top":"#171F56","bottom":"#5B65A5","far":"#475883","mid":"#32466D","ground":"#576A72","grass":"#354C61","leaf":"#344F70"}
}
var biome: String="meadow"
var variation: int=0
var glow_phase: float=0.0
var elapsed: float=0.0

static func choose_biome(types: Array) -> String:
    # Prioritize a character's first defining element. Default meadow.
    if types.has("幽靈") or types.has("惡"):
        return "moonforest"
    if types.has("水") or types.has("冰"):
        return "lakeside"
    if types.has("火"):
        return "sunset"
    if types.has("草") or types.has("蟲"):
        return "forest"
    return "meadow"

func setup(next_biome: String, next_variation: int=0) -> void:
    biome=next_biome if BIOMES.has(next_biome) else "meadow"
    variation=next_variation%3
    queue_redraw()

func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    set_process(true)

func _process(delta: float) -> void:
    elapsed+=delta
    if elapsed>=0.11:
        glow_phase+=elapsed
        elapsed=0.0
        queue_redraw()

func _ellipse(center: Vector2,rx: float,ry: float,color: Color,segments: int=32) -> void:
    var vertices=PackedVector2Array()
    for i in range(segments):
        var angle=TAU*float(i)/float(segments)
        vertices.append(center+Vector2(cos(angle)*rx,sin(angle)*ry))
    draw_colored_polygon(vertices,color)

func _curve_hill(top_y: float, amplitude: float, color: Color, phase: float) -> void:
    var vertices=PackedVector2Array([Vector2(0,480),Vector2(0,top_y)])
    for x in range(0,1021,20):
        var fx=float(x)
        vertices.append(Vector2(fx,top_y+sin(fx*.007+phase)*amplitude+cos(fx*.016+phase*2.0)*amplitude*.28))
    vertices.append(Vector2(1000,480))
    draw_colored_polygon(vertices,color)

func _cloud(x: float,y: float,scale_value: float,color: Color) -> void:
    _ellipse(Vector2(x,y+7*scale_value),58*scale_value,14*scale_value,color)
    draw_circle(Vector2(x-34*scale_value,y),22*scale_value,color)
    draw_circle(Vector2(x-9*scale_value,y-11*scale_value),27*scale_value,color)
    draw_circle(Vector2(x+28*scale_value,y-3*scale_value),21*scale_value,color)

func _tree(x: float,y: float,scale_value: float,dark: bool=false) -> void:
    var stem=Color("#475A61") if dark else Color("#896F57")
    var leaf=Color(str(COLORS[biome]["leaf"]))
    if dark:
        leaf=Color("#26365B")
    var p=Vector2(x,y)
    var s=scale_value
    draw_colored_polygon(PackedVector2Array([
        p+Vector2(-11,-2)*s,p+Vector2(-7,-116)*s,
        p+Vector2(9,-116)*s,p+Vector2(13,0)*s]),stem)
    for entry in [[-31,-120,39], [25,-116,42],[-4,-154,49],[-3,-104,45]]:
        draw_circle(p+Vector2(float(entry[0]),float(entry[1]))*s,float(entry[2])*s,leaf)
    if not dark:
        var flecks=Color("#B4E299",.65) if biome!="sunset" else Color("#E7B2AB",.62)
        draw_circle(p+Vector2(-19,-165)*s,17*s,flecks)
        draw_circle(p+Vector2(23,-135)*s,12*s,flecks)
        draw_line(p+Vector2(-4,-90)*s,p+Vector2(-4,-28)*s,Color("#AC916A",.7),3*s,true)

func _shrub(x: float,y: float,s: float,highlight: bool=true) -> void:
    var base=Color(str(COLORS[biome]["grass"]))
    for i in range(5):
        var cx=x+(float(i)-2.0)*16*s
        var cy=y-absf(float(i)-2.0)*3*s
        draw_circle(Vector2(cx,cy),20*s,base)
    if highlight:
        for i in range(3):
            draw_circle(Vector2(x+(i-1)*24*s,y-14*s),9*s,base.lightened(.24))

func _star(x: float,y: float,size_value: float,color: Color) -> void:
    draw_line(Vector2(x-size_value,y),Vector2(x+size_value,y),color,2,true)
    draw_line(Vector2(x,y-size_value),Vector2(x,y+size_value),color,2,true)
    draw_circle(Vector2(x,y),size_value*.35,color)

func _rock(x: float,y: float,s: float) -> void:
    var base=Color("#9BAEB0") if biome!="sunset" else Color("#A78F88")
    var points=PackedVector2Array([
        Vector2(x-23*s,y),Vector2(x-18*s,y-19*s),
        Vector2(x-3*s,y-27*s),Vector2(x+20*s,y-16*s),Vector2(x+25*s,y)])
    draw_colored_polygon(points,base)
    draw_line(Vector2(x-17*s,y-18*s),Vector2(x-3*s,y-24*s),base.lightened(.2),2,true)

func _flower(x: float,y: float,seed: int) -> void:
    var petal=Color("#FFFFFF") if seed%3==0 else (Color("#FEE2AD") if seed%3==1 else Color("#F5C7E4"))
    draw_line(Vector2(x,y),Vector2(x+2,y-15),Color(str(COLORS[biome]["grass"])),2,true)
    for i in range(5):
        var angle=float(i)*TAU/5.0
        draw_circle(Vector2(x+2+cos(angle)*5,y-15+sin(angle)*5),4,petal)
    draw_circle(Vector2(x+2,y-15),3,Color("#EBCB65"))

func _layered_sky() -> void:
    var upper=Color(str(COLORS[biome]["top"]))
    var lower=Color(str(COLORS[biome]["bottom"]))
    for i in range(24):
        var t=float(i)/23.0
        var c=upper.lerp(lower,t)
        draw_rect(Rect2(0,i*17,1000,18),c)

func _water() -> void:
    # Layered curved lake with small white reflected wavelets.
    _ellipse(Vector2(555,355),600,86,Color("#A5D8DB",.86))
    _ellipse(Vector2(580,360),535,67,Color("#70B8CA",.85))
    _ellipse(Vector2(590,391),476,29,Color("#3E9DB5",.43))
    for i in range(30):
        var x=50.0+float(i%10)*94.0+float((i*7)%19)
        var y=327.0+float(i/10)*26.0
        draw_line(Vector2(x,y),Vector2(x+29+float(i%4)*9,y),Color("#E6FBF9",.65),2,true)

func _draw() -> void:
    if size.x<=0.0 or size.y<=0.0:
        return
    draw_set_transform(Vector2.ZERO,0.0,Vector2(size.x/1000.0,size.y/480.0))
    _layered_sky()
    var night=biome=="moonforest"
    if night:
        for i in range(44):
            var x=float((i*181+43+variation*37)%997)
            var y=float((i*73+19)%208)
            var glimmer=.5+.35*sin(glow_phase*1.6+float(i))
            _star(x,y,2.0+float(i%3),Color("#E7E3FF",glimmer))
        draw_circle(Vector2(775,83),74,Color("#DADBF1",.11))
        draw_circle(Vector2(775,83),52,Color("#E1E5F0",.20))
        draw_circle(Vector2(775,83),33,Color("#FFF4D5"))
        draw_circle(Vector2(784,75),31,Color("#FDF2D3",.97))
    else:
        var sun_pos=Vector2(765,86) if biome!="sunset" else Vector2(728,166)
        for i in range(9,0,-1):
            draw_circle(sun_pos,float(i)*14.0,Color("#FFE8BA",.015+float(9-i)*.008))
        draw_circle(sun_pos,35,Color("#FFF6CA"))
        var cloud_color=Color("#FCFDFF",.85) if biome!="sunset" else Color("#FFE0CF",.52)
        _cloud(130+sin(glow_phase*.12)*17,78,.85,cloud_color)
        _cloud(493+cos(glow_phase*.09)*15,52,.67,cloud_color)
        if biome!="forest":
            _cloud(884+sin(glow_phase*.11)*13,143,.49,cloud_color)
    # Mountains, rolling woods, and atmospheric perspective.
    var far=Color(str(COLORS[biome]["far"]))
    _curve_hill(241,31,far,.8+variation*.26)
    if biome=="sunset" or biome=="lakeside":
        for peak in [[125,250,170],[396,235,198],[671,240,192],[920,250,143]]:
            var px=float(peak[0]);var py=float(peak[1]);var height=float(peak[2])
            draw_colored_polygon(PackedVector2Array([Vector2(px-125,py+60),Vector2(px,py-height),Vector2(px+155,py+67)]),far.darkened(.08))
            draw_colored_polygon(PackedVector2Array([Vector2(px-22,py-height+34),Vector2(px,py-height),Vector2(px+32,py-height+39)]),Color("#F6E5DB",.6))
    var mid=Color(str(COLORS[biome]["mid"]))
    _curve_hill(302,35,mid,2.45+variation*.26)
    if biome=="forest" or night:
        for i in range(13):
            var x=float(i)*89.0+27
            var y=300.0+sin(float(i)*1.6)*25.0
            _tree(x,y,.75+float(i%3)*.09,night)
    if biome=="lakeside":
        _water()
    else:
        _curve_hill(377,22,Color(str(COLORS[biome]["ground"])),.3)
    # Large framing trees; keep middle readable for the Pokemon sprites.
    if biome=="forest" or night:
        _tree(6,414,1.62,night)
        _tree(977,397,1.42,night)
    elif biome=="lakeside":
        _tree(23,438,1.28,false)
        _tree(973,421,1.13,false)
    elif biome=="sunset":
        _tree(-11,443,1.13,false)
        _tree(980,411,1.16,false)
    else:
        _tree(16,445,1.1,false)
        _tree(974,438,1.05,false)
    # Two distinct ground pads encode foreground player vs distant opponent.
    _ellipse(Vector2(248,411),147,31,Color("#314C53",.17))
    _ellipse(Vector2(745,324),111,23,Color("#2C4E52",.16))
    _ellipse(Vector2(248,402),137,18,Color("#D8E7B9",.32))
    _ellipse(Vector2(745,315),101,14,Color("#E9E6C8",.26))
    # Foreground bushes and flowers create depth without covering the fighters.
    _shrub(33,462,1.32,not night)
    _shrub(960,464,1.46,not night)
    _shrub(488,483,.84,false)
    for i in range(20):
        var x=40.0+float((i*137+variation*41)%940)
        var y=445.0+float((i*19)%39)
        draw_line(Vector2(x,y),Vector2(x+2.0,y-12.0-float(i%4)*3.0),Color(str(COLORS[biome]["grass"]),.78),2,true)
    for i in range(11):
        var x=83.0+float((i*83+variation*59)%851)
        var y=439.0+float((i*13)%34)
        if not night:
            _flower(x,y,i)
        else:
            _star(x,y-20,3,Color("#9DDCDB",.45+.2*sin(glow_phase*2.0+float(i))))
    _rock(422,448,.7)
    _rock(887,439,.62)
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
