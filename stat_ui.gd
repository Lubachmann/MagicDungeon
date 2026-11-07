extends RefCounted
## Shared icon vocabulary and last-drawn contextual help. No game-state mutation.
const DATA={
 "iron":["iron","Iron","Spend iron to upgrade equipment or add paid infusions at a forge. Iron lasts for the current run."],
 "impact_power":["stat_attack","Physical power","Multiplies the whole physical hit, including character attack and equipment attack. Does not increase Fire damage."],
 "impact_rate":["speed","Attack rate","Changes final attack rate after other speed bonuses. −20% attack rate makes the attack interval 25% longer."],
 "attack":["stat_attack","Attack damage","Hit power before enemy armor, criticals and conditional bonuses. Item attack is added after the weapon scales character attack."],
 "weapon_dps":["stat_attack","Weapon damage per second","Attack damage divided by attack interval. Excludes armor, criticals, elements and weapon procs."],
 "armor":["armor","Armor","Reduces physical hit damage with diminishing returns. Select Armor in Your build to see your resulting physical reduction. Fire and poison ignore armor."],
 "health":["health","Maximum health","Adds to your maximum HP. Equipping more maximum health does not heal you."],
 "current_hp":["health","Current health","Health you have now. At 0 HP the run ends."],
 "max_hp":["health","Maximum health","Your maximum HP, including equipment, levels and permanent upgrades."],
 "interval":["speed","Attack interval","Seconds between attacks with your complete build. Lower is faster."],
 "base_interval":["speed","Base weapon interval","This weapon's normal interval before speed bonuses. Lower is faster."],
 "item_interval":["speed","Item attack interval","Weapon interval after this item's own speed bonus. Other equipment and character upgrades can change your final interval."],
 "speed":["speed","Attack speed bonus","A percentage bonus to attack rate. Final interval uses base interval / (1 + speed bonuses), then applies special weapon effects."],
 "crit_chance":["crit","Critical chance","Chance for a weapon hit to deal critical damage, up to your current critical chance limit."],
 "crit_mult":["crit_damage","Critical damage","150% total critical damage means 1.5 times normal hit power. Equipment bonuses add percentage points to that total."],
 "crit_cap":["crit","Critical chance limit","Maximum effective critical chance. Certain later upgrades raise this limit."],
 "evade":["evade","Evade chance","Chance to avoid an entire enemy attack automatically. Maximum 50%."],
 "vampirism":["vampirism","Vampirism","Heals a percentage of weapon damage dealt, excluding overkill. Partial healing adds up across fights. Fire and poison do not heal. Maximum 35%."],
 "fire_power":["stat_fire","Fire","Each Fire adds a burn equal to 10% of hit power per second. Physical-only bonuses do not boost burns. Only the strongest burn deals damage."],
 "fire":["stat_fire","Burn damage","Fire burns enemies over time and ignores armor. Stronger hits cause stronger burns. Only the strongest burn deals damage."],
 "frost_apply":["stat_ice","Frost power","Each stack slows attacks 5% (max 50%). At 10 stacks, freeze for 1s. Slower weapon types add more per hit; speed bonuses and penalties do not."],
 "ice":["stat_ice","Frost per hit","Each Frost stack slows attacks by 5% (max 50%). At 10 stacks, freeze for 1s, then return to 5. Normal freeze cooldown: 8s."],
 "acid_apply":["stat_acid","Acid power","Each stack removes 1 armor. Extra stacks add weapon damage after armor reaches 0. Slower weapon types add more per hit; speed bonuses and penalties do not."],
 "acid":["stat_acid","Acid per hit","Each Acid stack removes 1 armor. At 0 armor, each extra stack adds 1% weapon damage (max 20%). Stacks last the fight."],
 "poison_apply":["stat_poison","Poison power","Each stack deals 0.5 damage every 0.5s. 3 stacks = 1.5 damage. Slower weapon types add more per hit; speed bonuses and penalties do not."],
 "poison":["stat_poison","Poison per hit","Each Poison stack deals 0.5 damage every 0.5s. Example: 3 stacks deal 1.5 damage every 0.5s. Stacks last the fight and ignore armor."],
 "fire_dps":["stat_fire","Fire damage per second","Burn damage supplied by this item. Older runs use their original elemental rules."],
 "ice_slow":["stat_ice","Enemy attack slow","Slows enemy attacks in older runs. New runs use Frost counters."],
 "acid_strip":["stat_acid","Armor removed per hit","Armor removed by this item in older runs. New runs use Acid counters."],
 "poison_weak":["stat_poison","Enemy damage reduction","Poison weakening in older runs. New runs use stacking poison damage."],
 "armor_reduction":["armor","Physical reduction","A result of armor, not an item stat. Reduction = armor / (12 + armor), before rounding. See Armor details in Your build."],
 "victory_heal":["health","Health after victory","Flat HP restored after winning an encounter."],
 "third_heal":["health","Health every three hits","Flat healing every three weapon attacks. Separate from vampirism."],
 "armor_pierce":["attack","Armor ignored","Percentage of remaining enemy armor ignored by your physical hits."],
 "opening_damage":["attack","Opening hit bonus","Additional hit power on the first attack of an encounter."],
 "first_hit_reduction":["armor","Opening protection","Reduces the first incoming enemy hit."],
 "acid_cap":["stat_acid","Corrosion limit","Maximum armor removal for an older run's acid effect."],
 "shield":["armor","Shield","Absorbs incoming damage before health. Temporary protection rather than armor."],
 "xp":["book","Experience","Earned from defeated enemies. Fills the XP bar and grants temporary run levels."],
 "level":["book","Character level","Temporary level for this run. Experience and levels reset on death."],
 "power":["attack","Character attack multiplier","Scales character attack before equipment attack is added. It is a weapon rule, not a separate damage bonus."]}
var g
var regions=[]
var notice=""
var notice_left=0.0
var notice_age=0.0
var blocked=false
func _init(game):g=game
func pointer() -> Vector2:
 if g.choice_ui and g.choice_ui.pointer.x>-9999 and not g.menu_keyboard:return g.choice_ui.pointer
 return g.design_mouse()
func begin() -> void:regions.clear()
func info(key: String) -> Array:
 if g.run_rules>=17 and key in ["frost_apply","ice","acid_apply","acid","fire_power","fire","poison_apply","poison"]:
  var entry=DATA[key];var build=preload("res://build_stats.gd").calculate(g).build
  var element="ice" if key in ["frost_apply","ice"] else "acid" if key in ["acid_apply","acid"] else "fire" if key in ["fire_power","fire"] else "poison"
  return [entry[0],entry[1],preload("res://element_rules.gd").describe(element,build,g.attack)]
 if key.begins_with("enemy_"):
  var stat=key.trim_prefix("enemy_");var entry=DATA.get(stat,DATA.level)
  var descriptions={"current_hp":"Remaining enemy HP. Defeating it grants experience and embers.","attack":"Enemy hit power before your armor and defensive effects. Specials and rage can increase it.","armor":"Remaining enemy armor after corrosion. Reduces your physical hit damage. Fire and poison ignore it.","interval":"Seconds between enemy attacks. Frost slows attacks; rage can speed them up.","level":"A threat indicator based on floor, room depth and enemy role. Use actual stats and encounter risk to judge your build."}
  return [entry[0],"Enemy "+entry[1].to_lower(),descriptions.get(stat,entry[2])]
 return DATA.get(key,["book",key.replace("_"," ").capitalize(),"Select this value in Your build for its sources and rules."])
func resolve(label_text: String) -> String:
 var name=label_text.to_lower()
 if "burn" in name:return "fire"
 for element in ["fire","frost","ice","poison","acid"]:
  if element in name:return {"fire":"fire_power","frost":"ice","ice":"ice","poison":"poison","acid":"acid"}[element]
 if "shield" in name:return "shield"
 for key in DATA:
  if name==str(DATA[key][1]).to_lower():return key
 return {"max hp":"max_hp","health":"max_hp","attack":"attack","armor":"armor","attack every":"interval","critical hit damage":"crit_mult","crit chance limit":"crit_cap","evade chance":"evade","hp after victory":"victory_heal","hp every 3 attacks":"third_heal","armor ignored":"armor_pierce","first hit bonus":"opening_damage","first hit protection":"first_hit_reduction"}.get(name,"attack")
func upgrade(id: String,blessing: bool,at: Vector2) -> bool:
 var stacks=g.choice_ui.STACKS.get(id,[]) if not blessing else ([id] if id in ["fire","ice","acid","poison"] else [])
 if not stacks.is_empty():
  for i in range(stacks.size()):
   var element=stacks[i];icon({"fire":"fire_power","ice":"ice","acid":"acid","poison":"poison"}[element],at+Vector2(i*156,-26),30)
   g.text(at+Vector2(40+i*156,0),(g.choice_ui.element_gain(element)+("/hit" if element!="fire" else "")) if g.run_rules>=9 else "+1",29,g.TEAL)
  return true
 var before=preload("res://build_stats.gd").calculate(g);var after=preload("res://build_stats.gd").upgrade_preview(g,id,blessing)
 var key={"attack":"attack","guard":"armor","focus":"crit_chance","ferocity":"crit_mult","precision":"crit_chance","ruin":"crit_mult","haste":"interval","critical_horizon":"crit_cap","unbound_aim":"crit_cap"}.get(id,"")
 if key=="":return false
 icon(key,at+Vector2(0,-26),30)
 var value=g.build_view.value(key,after) if key=="interval" else ("%+.0f%%"%((float(after[key])-float(before[key]))*100) if key in ["crit_mult","crit_chance","crit_cap"] else "%+.1f"%(float(after[key])-float(before[key])))
 g.text(at+Vector2(40,0),value,31,g.TEAL)
 if id=="guard":icon("interval",at+Vector2(0,12),26);g.text(at+Vector2(40,37),g.build_view.value("interval",after),26,g.TEAL)
 return true
func register(key: String,rect: Rect2,title: String="",description: String="") -> void:
 var entry=info(key);regions.append({"rect":rect,"key":key,"title":entry[1] if title=="" else title,"description":entry[2] if description=="" else description})
func icon(key: String,at: Vector2,size: int=24,title: String="",description: String="") -> void:
 if key.trim_prefix("enemy_") not in ["health","max_hp","current_hp","xp","level"]:g.ui_icon(info(key)[0],at,size)
 register(key,Rect2(at,Vector2(size,size)).grow(5),title,description)
func short_name(key: String) -> String:
 var names={"impact_power":"Physical power","impact_rate":"Attack rate","attack":"Attack","weapon_dps":"Damage/s","armor":"Armor","health":"Max HP","current_hp":"Current HP","max_hp":"Max HP","interval":"Interval","base_interval":"Base interval","item_interval":"Item interval","speed":"Speed bonus","crit_chance":"Crit chance","crit_mult":"Crit damage","crit_cap":"Crit limit","evade":"Evade","vampirism":"Vampirism","fire_power":"Fire potency","fire":"Fire /s","frost_apply":"Frost power","ice":"Frost /hit","acid_apply":"Acid power","acid":"Acid /hit","poison_apply":"Poison power","poison":"Poison /hit","fire_dps":"Fire /s","ice_slow":"Slow","acid_strip":"Armor loss","poison_weak":"Weakness","victory_heal":"Victory heal","third_heal":"Hit healing","armor_pierce":"Armor pierce","opening_damage":"Opening hit","first_hit_reduction":"First hit guard","acid_cap":"Acid limit","shield":"Shield","xp":"XP","level":"Level"}
 var clean=key.trim_prefix("enemy_")
 return names.get(clean,info(key)[1])
func label(key: String,baseline: Vector2,size: int=24) -> void:icon(key,baseline-Vector2(0,size-5),size)
func scaling(item: Dictionary,baseline: Vector2,width: float,before: Dictionary={}) -> void:
 if item.get("slot","")!="weapon":return
 var factor=float(preload("res://equipment_presenter.gd").numbers(item).power)
 var text="Character attack × %.0f%%"%(factor*100)
 if not before.is_empty():text="Character attack × %.0f%% → %.0f%%"%[float(preload("res://equipment_presenter.gd").numbers(before).power)*100,factor*100]
 g.panel(Rect2(baseline-Vector2(0,24),Vector2(width,34)))
 g.text(baseline+Vector2(8,0),text,18,g.TEAL)
 var s=preload("res://build_stats.gd").calculate(g)
 var character=(float(s.attack)/maxf(0.01,1.0+float(s.gear.get("impact_power",0)))-float(s.gear.get("attack",0)))/maxf(0.01,float(s.power_scale))
 var own=float(g.Gear.stats(item).get("attack",0))
 var description="This weapon scales your character attack, then adds equipment attack. Example with your character: %.1f × %.0f%% + %.1f weapon attack = %.1f hit power, before other equipment attack. Character attack includes base damage, levels, Might and run attack upgrades. It does not multiply the weapon's own attack."%[character,factor*100,own,character*factor+own]
 if float(preload("res://equipment.gd").stats(item).get("impact_power",0))>0:
  description+=" This weapon then increases the entire physical hit by 60%. Fire damage does not receive this bonus."
 register("power",Rect2(baseline-Vector2(0,24),Vector2(width,34)),"Character attack multiplier",description)
func tick(delta: float) -> void:notice_left=maxf(0,notice_left-delta);notice_age+=delta
static func is_blocked(message: String) -> bool:
 var lower=message.to_lower()
 for word in ["locked","sealed","blocked","requires","need ","no bombs","out of reach","invalid","unprotect"]:
  if word in lower:return true
 return lower.begins_with("find ") or ("defeat " in lower and " first" in lower) or lower.begins_with("deep water") or lower.begins_with("flooded shortcut")
func notify(message: String) -> void:
 var important=is_blocked(message)
 if g.mode=="fight" and not important:return
 if blocked and notice_left>2 and not important:return
 if message==notice and notice_left>0:notice_left=maxf(notice_left,5.0 if important else 2.8);return
 notice=message;blocked=important;notice_age=0;notice_left=5.0 if important else 2.8
 if important and g.sound:g.sfx("error")
func draw_notice() -> void:
 if notice_left<=0 or g.mode not in ["play","inspect","bomb"]:return
 var reduced=g.feedback and g.feedback.reduced()
 var rise=0.0 if reduced else 12.0*pow(maxf(0,1-notice_age/0.22),3)
 var rect=Rect2(12,275-rise,295,128);g.panel(rect,Color("302a24") if blocked else Color("23353b"))
 if blocked:g.draw_rect(rect.grow(-3),g.GOLD,false,2)
 g.ui_icon("key" if blocked else "book",rect.position+Vector2(13,14),26)
 g.text(rect.position+Vector2(50,25),"BLOCKED" if blocked else "NOTICE",20,g.GOLD)
 g.draw_wrapped(notice,rect.position+Vector2(15,54),265,20,g.INK,4)
func draw_tooltip() -> void:
 var mouse=pointer();var target={}
 for region in regions:
  if region.rect.has_point(mouse):target=region
 if target.is_empty():return
 var at=mouse+Vector2(18,20);at.x=clampf(at.x,20,840);at.y=clampf(at.y,20,520)
 g.panel(Rect2(at,Vector2(420,300)),Color("23353b"));g.text(at+Vector2(18,34),target.title,24,g.GOLD)
 g.draw_wrapped(target.description,at+Vector2(18,70),384,20,g.INK,8)
