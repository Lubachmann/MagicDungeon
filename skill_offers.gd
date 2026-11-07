extends RefCounted
# Rarity and eligibility describe offers only; owned skills always keep their effects.
const RARE=["quickdraw","needle","wildfire","shatter","bulwark","contagion","critical_horizon","glacial_crusher","venom_edge","caustic_burn","frozen_precision","blood_harvest","shieldbreaker","warded_blade","ashen_charge","breakthrough","combustion","toxic_harvest","exposed_core"]
const EPIC=["steamglass","corrosive_flame","black_ice","toxic_spark","unbound_aim","toxic_glacier","frost_shatter"]
const HEAVY_NEW=["breakthrough","frost_shatter"]
const SPECIALIZED=["combustion","toxic_harvest","exposed_core"]
const NEW=["glacial_crusher","venom_edge","caustic_burn","frozen_precision","blood_harvest","shieldbreaker","warded_blade","ashen_charge","toxic_glacier"]
static func rarity(id: String) -> String:
 return "Epic" if id in EPIC else "Rare" if id in RARE else "Common"
static func eligible(g,id: String,totals: Dictionary) -> bool:
 var weapon=str(totals.get("build",{}).get("weapon",""))
 # BuildStats derives the equipped archetype independently of the UI.
 var index=int(g.equipped.get("weapon",-1))
 weapon=str(g.inventory[index].get("archetype","unarmed")) if index>=0 and index<g.inventory.size() else "unarmed"
 var e=totals.element_totals
 # Future-facing offers allow deliberate investments; their descriptions retain requirements.
 if g.run_rules>=18 and id in ["combustion","toxic_harvest","exposed_core","glacial_crusher","venom_edge","caustic_burn","frozen_precision","blood_harvest","shieldbreaker","breakthrough","frost_shatter","warded_blade","ashen_charge","toxic_glacier"]:return true
 match id:
  "combustion":return weapon in ["axe","greatblade"] and preload("res://element_rules.gd").element_power(totals.build,"fire")>=4
  "toxic_harvest":return preload("res://element_rules.gd").element_power(totals.build,"poison")>=4
  "exposed_core":return preload("res://element_rules.gd").element_power(totals.build,"acid")>=4
  "glacial_crusher":return weapon in ["axe","greatblade"] and e.ice>0
  "venom_edge":return weapon=="dagger" and e.poison>0
  "caustic_burn":return e.fire>0 and e.acid>0
  "frozen_precision":return e.ice>0 and totals.crit_raw>0
  "blood_harvest":return e.poison>0 and totals.vampirism>0
  "shieldbreaker":return weapon in ["axe","greatblade"]
  "breakthrough":return weapon in ["axe","greatblade"]
  "frost_shatter":return weapon in ["axe","greatblade"] and e.ice>0
  "warded_blade":return weapon=="balanced" and (not g.inventory[index].get("plain",false) or "bulwark" in g.relics or "black_ice" in g.relics)
  "ashen_charge":return e.fire>0
  "toxic_glacier":return e.ice>0 and e.poison>0
 return true
static func pool(g) -> Array:
 var totals=preload("res://build_stats.gd").calculate(g);var result=[]
 for id in g.RELICS:
  if id in g.relics:continue
  if g.sanctuary and g.sanctuary.active() and g.sanctuary.SKILLS.has(id) and not g.sanctuary.unlocked(g.sanctuary.SKILLS[id]):continue
  if g.run_rules<18 and id in ["heavy_momentum","quickdraw"]:continue
  if g.run_rules<17 and id in SPECIALIZED:continue
  if g.run_rules<14 and id in HEAVY_NEW:continue
  if rarity(id)=="Rare" and g.reward_level<4:continue
  if rarity(id)=="Epic" and g.reward_level<7:continue
  if id=="critical_horizon" and (g.reward_level<5 or totals.crit_raw<0.35):continue
  if id=="unbound_aim" and (g.reward_level<9 or "critical_horizon" not in g.relics or totals.crit_raw<0.55):continue
  if eligible(g,id,totals):result.append(id)
 return result
static func choose(g,excluded: Array=[]) -> Array:
 var all=pool(g);var candidates=[]
 for id in all:
  if id not in excluded:candidates.append(id)
 var count=4 if g.ember_tree.rank("insight")>0 else 3
 if candidates.size()<count:
  for id in excluded:
   if id in all and id not in candidates:candidates.append(id)
 var result=[];var rare_luck=0.10*g.ember_tree.rank("transmutation");var epic_luck=0.10*g.ember_tree.rank("convergence")
 while result.size()<count and not candidates.is_empty():
  var rare_chance=clampf((0.12 if g.reward_level<6 else 0.32)+rare_luck,0.0,0.70) if g.reward_level>=4 else 0.0
  var epic_chance=clampf(0.08+epic_luck,0.0,0.30) if g.reward_level>=7 else 0.0
  var roll=g.rng.randf();var wanted="Epic" if roll<epic_chance else "Rare" if roll<epic_chance+rare_chance else "Common"
  var bucket=[]
  for id in candidates:
   if rarity(id)==wanted:bucket.append(id)
  if bucket.is_empty():bucket=candidates.duplicate()
  var picked=bucket[g.rng.randi_range(0,bucket.size()-1)];result.append(picked);candidates.erase(picked)
 if g.run_rules>=18 and not result.is_empty():
  var fallback=["precision","ruin","leech","ward","bloom","spark"]
  var found=false
  for id in result:
   if id in fallback:found=true
  if not found:
   var available=[]
   for id in candidates:
    if id in fallback:available.append(id)
   if not available.is_empty():result[result.size()-1]=available[g.rng.randi_range(0,available.size()-1)]
 return result
