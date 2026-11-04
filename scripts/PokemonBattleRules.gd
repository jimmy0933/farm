extends RefCounted
## Small, deterministic rules layer for a preschool-friendly one-on-one battle.
## Each Pokemon has two ATTACKING moves even if its lesson data includes a
## status-only move such as Hypnosis or Withdraw.
const MAX_HP: int = 100
const TYPE_ICONS = {
    "一般":"⭐", "火":"🔥", "水":"💧", "電":"⚡",
    "草":"🌿", "冰":"❄️", "格鬥":"🥊", "毒":"☠️",
    "地面":"⛰️", "飛行":"🪽", "超能力":"🔮", "蟲":"🐛",
    "岩石":"🪨", "幽靈":"👻", "龍":"🐉", "惡":"🌑",
    "鋼":"⚙️", "妖精":"🧚"
}
const TYPE_COLORS = {
    "一般":"#EFE8D7", "火":"#FEE4CE", "水":"#D3EFFB", "電":"#FFF2AE",
    "草":"#DDF5D1", "冰":"#DEECFA", "格鬥":"#F8D8C7", "毒":"#EED8FA",
    "地面":"#F2E5CB", "飛行":"#DBEDFB", "超能力":"#F7E0F2", "蟲":"#E5F1CA",
    "岩石":"#E9DFC6", "幽靈":"#E6DDF6", "龍":"#D9E6FE", "惡":"#E7DCE5",
    "鋼":"#E5E8EE", "妖精":"#FFE4F0"
}
# [weak targets, resistant targets, immune targets].
const CHART = {
    "一般":[[],["岩石","鋼"],["幽靈"]],
    "火":[["草","冰","蟲","鋼"],["火","水","岩石","龍"],[]],
    "水":[["火","地面","岩石"],["水","草","龍"],[]],
    "電":[["水","飛行"],["電","草","龍"],["地面"]],
    "草":[["水","地面","岩石"],["火","草","毒","飛行","蟲","龍","鋼"],[]],
    "冰":[["草","地面","飛行","龍"],["火","水","冰","鋼"],[]],
    "格鬥":[["一般","冰","岩石","惡","鋼"],["毒","飛行","超能力","蟲","妖精"],["幽靈"]],
    "毒":[["草","妖精"],["毒","地面","岩石","幽靈"],["鋼"]],
    "地面":[["火","電","毒","岩石","鋼"],["草","蟲"],["飛行"]],
    "飛行":[["草","格鬥","蟲"],["電","岩石","鋼"],[]],
    "超能力":[["格鬥","毒"],["超能力","鋼"],["惡"]],
    "蟲":[["草","超能力","惡"],["火","格鬥","毒","飛行","幽靈","鋼","妖精"],[]],
    "岩石":[["火","冰","飛行","蟲"],["格鬥","地面","鋼"],[]],
    "幽靈":[["超能力","幽靈"],["惡"],["一般"]],
    "龍":[["龍"],["鋼"],["妖精"]],
    "惡":[["超能力","幽靈"],["格鬥","惡","妖精"],[]],
    "鋼":[["冰","岩石","妖精"],["火","水","電","鋼"],[]],
    "妖精":[["格鬥","龍","惡"],["火","毒","鋼"],[]]
}
# First move is a repeatable, modest attack; second is stronger and must
# rest one turn before it can be used again. These names are game approximations.
const MOVES = {
    25:[["電光一閃","一般"],["十萬伏特","電"]],
    94:[["毒液衝擊","毒"],["暗影球","幽靈"]],
    133:[["撞擊","一般"],["咬住","惡"]],
    103:[["念力","超能力"],["種子炸彈","草"]],
    810:[["木枝突刺","草"],["飛葉快刀","草"]],
    7:[["撞擊","一般"],["水槍","水"]],
    79:[["水槍","水"],["念力","超能力"]],
    574:[["念力","超能力"],["幻象光線","超能力"]],
    4:[["抓","一般"],["火花","火"]],
    9:[["水槍","水"],["水炮","水"]],
    54:[["水槍","水"],["念力","超能力"]],
    190:[["抓","一般"],["暗影爪","幽靈"]]
}
const EN_MOVES = {
    "電光一閃":"Quick Attack", "十萬伏特":"Thunderbolt",
    "舌舔":"Lick", "暗影球":"Shadow Ball", "撞擊":"Tackle",
    "念力":"Confusion", "種子炸彈":"Seed Bomb", "木枝突刺":"Branch Poke",
    "飛葉快刀":"Razor Leaf", "水槍":"Water Gun", "幻象光線":"Psybeam",
    "抓":"Scratch", "火花":"Ember", "水炮":"Hydro Pump",
    "高速星星":"Swift", "電擊":"Thunder Shock",
    "毒液衝擊":"Venoshock", "咬住":"Bite", "暗影爪":"Shadow Claw", "影子球":"Shadow Ball",
    "催眠術":"Hypnosis", "縮入殼中":"Withdraw"
}

static func icon(type_name: String) -> String:
    return str(TYPE_ICONS.get(type_name,"✨"))

static func type_color(type_name: String) -> Color:
    return Color(str(TYPE_COLORS.get(type_name,"#E8E8E8")))

static func moves_for(id: int) -> Array:
    return MOVES.get(id,[["撞擊","一般"],["高速星星","一般"]])

static func effectiveness(attack_type: String, defending_types: Array) -> float:
    var rules: Array=CHART.get(attack_type,[[],[],[]])
    var result: float=1.0
    for defensive_type in defending_types:
        if rules[2].has(defensive_type):
            return 0.0
        if rules[0].has(defensive_type):
            result*=2.0
        elif rules[1].has(defensive_type):
            result*=0.5
    return result

static func weaknesses(defending_types: Array) -> Array:
    var result: Array=[]
    for attack_type in CHART:
        if effectiveness(str(attack_type),defending_types)>1.0:
            result.append(attack_type)
    return result

static func strike(attacker: Dictionary, defender: Dictionary, move_slot: int, randomizer: RandomNumberGenerator) -> Dictionary:
    var slot: int=clampi(move_slot,0,1)
    var move: Array=moves_for(int(attacker["id"]))[slot]
    var base: int=randomizer.randi_range(12,20) if slot==0 else randomizer.randi_range(20,30)
    # x1.2 for weakness, x0.85 for resistance, and 0 for immunity.
    var eff: float=effectiveness(str(move[1]),defender.get("types",[]))
    var mult: float=1.2 if eff>1.0 else (0.0 if eff==0.0 else (0.85 if eff<1.0 else 1.0))
    var damage: int=roundi(float(base)*mult)
    return {"name":str(move[0]),"type":str(move[1]),"damage":damage,"effectiveness":eff,"strong":slot==1}

static func clamp_health(health: int, damage: int) -> int:
    return clampi(health-maxi(0,damage),0,MAX_HP)
